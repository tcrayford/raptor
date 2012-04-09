module Raptor
  class Router
    def initialize(app, routes)
      @app = app
      @routes = routes
    end

    def self.build(app, &block)
      routes = BuildsRoutes.new(app).build(&block)
      new(app, routes)
    end

    def call(env)
      request = Rack::Request.new(env)
      Raptor.log "App: routing #{request.request_method} #{request.path_info}"
      injector = Injector.for_app(@app).
        add_request(request)
      injector = Injector.new.add_request(request)
      begin
        route = route_for_request(injector, request)
      rescue NoRouteMatches
        Raptor.log("No route matches")
        return Rack::Response.new("", 404)
      end

      begin
        route.respond_to_request(injector, request)
      rescue Exception => e
        Raptor.log("Looking for a redirect for #{e.inspect}")
        action = route.action_for_exception(e) or raise
        route_named(action).respond_to_request(injector, request)
      end
    end

    def route_for_request(injector, request)
      @routes.find { |route| route.match?(injector, request) } or
        raise NoRouteMatches
    end

    def route_named(action_name)
      @routes.find { |route| route.name == action_name }
    end
  end

  module StandardRoutes
    def root(*params)
      options = options(params)
      route(:root, "GET", "/", options)
    end

    def show(*params)
      options = options(params)
      route(:show, "GET", "/:id",
            {:present => default_single_presenter,
              :to => delegate(options),
              :with => :find_by_id}.merge(options))
    end

    def new(*params)
      options = options(params)
      route(:new, "GET", "/new",
            {:present => default_single_presenter,
              :to => delegate(options),
             :with => :new}.merge(options))
    end

    def index(*params)
      options = options(params)
      route(:index, "GET", "/",
            {:present => default_list_presenter,
              :to => delegate(options),
              :with => :all}.merge(options))
    end

    def create(*params)
      options = options(params)
      route(:create, "POST", "/",
            {:redirect => :show,
             ValidationError => :new,
              :to => delegate(options),
              :with => :create}.merge(options))
    end

    def edit(*params)
      options = options(params)
      route(:edit, "GET", "/:id/edit",
            {:present => default_single_presenter,
              :to => delegate(options),
              :with => :find_by_id}.merge(options))
    end

    def update(*params)
      options = options(params)
      route(:update, "PUT", "/:id",
            {:redirect => :show,
             ValidationError => :edit,
              :to => delegate(options),
              :with => :find_and_update}.merge(options))
    end

    def destroy(*params)
      options = options(params)
      route(:destroy, "DELETE", "/:id",
            {:redirect => :index,
              :to => delegate(options),
              :with => :destroy}.merge(options))
    end

    def delegate(options)
      options[:to] || record_module
    end
  end

  class BuildsRoutes
    include StandardRoutes

    def initialize(app, parent_path="")
      @app = app
      @parent_path = parent_path
      @routes = []
    end

    def build(&block)
      instance_eval(&block)
      @routes
    end

    def path(sub_path_name, &block)
      routes = BuildsRoutes.new(@app, "/" + sub_path_name).build(&block)
      routes.each { |route| route.add_neighbors(routes) }
      @routes += routes
    end

    def last_parent_path_component
      @parent_path.split(/\//).last or raise CantInferModulePathsForRootRoutes
    end

    def default_single_presenter
      Raptor::Util.camel_case(last_parent_path_component)
    end

    def default_list_presenter
      default_single_presenter + "List"
    end

    def record_module
      records_name = Raptor::Util.camel_case(last_parent_path_component)
      @app.const_get(:Records).const_get(records_name)
    end

    def options(params)
      case params.length
      when 0
        {}
      when 1
        params.last
      when 2
        {:to => params[0],
          :with => params[1]}
      when 3
        {:to => params[0],
          :with => params[1]}.merge(params.last)
      end
    end

    def route(action, http_method, path, *params)
      options = options(params)
      path = @parent_path + path
      Raptor::ValidatesRoutes.validate_route_params!(options)
      options = options.merge(:action => action,
                            :http_method => http_method,
                            :path => path)
      route = Route.for_app(@app, @parent_path, options)
      @routes << route
      route
    end
  end

  class CantInferModulePathsForRootRoutes < RuntimeError; end

  class RouteOptions
    def initialize(app, parent_path, params)
      @app = app
      @parent_path = parent_path
      @params = params
    end

    def action; @params.fetch(:action); end
    def http_method; @params.fetch(:http_method); end
    def path; @params.fetch(:path); end

    def delegator
      delegate = @params.fetch(:to, Raptor::NullDelegate)
      method_name = @params.fetch(:with, :do_nothing)
      Raptor::Delegator.new(delegate, method_name)
    end

    def exception_actions
      @params.select do |maybe_exception, maybe_action|
        maybe_exception.is_a?(Class)
      end
    end

    def responder
      redirect = @params[:redirect]
      text = @params[:text]
      presenter = @params[:present].to_s
      template_path = @params[:render]

      if redirect.is_a?(String)
        RedirectResponder.new(redirect)
      elsif redirect
        ActionRedirectResponder.new(@app, redirect)
      elsif text
        PlaintextResponder.new(text)
      elsif template_path
        TemplateResponder.new(@app, presenter, template_path, path)
      else
        ActionTemplateResponder.new(@app, presenter, @parent_path, action)
      end
    end

    def constraints
      standard_constraints + custom_constraints
    end

    def standard_constraints
      [HttpMethodConstraint.new(http_method),
       PathConstraint.new(path)]
    end

    def custom_constraints
      return [] unless @params.has_key?(:if)
      name = @params.fetch(:if).to_s
      Constraints.new(@app).matching(name)
    end
  end

  class Constraints
    def initialize(app_module)
      @app_module = app_module
    end

    def matching(name)
      constraint = @app_module::Constraints.const_get(Util.camel_case(name))
      [constraint]
    end
  end

  class NoRouteMatches < RuntimeError; end

  class Route
    attr_reader :name, :path

    def initialize(name, path, constraints, delegator, responder,
                   exception_actions)
      @name = name
      @path = path
      @constraints = constraints
      @delegator = delegator
      @responder = responder
      @exception_actions = exception_actions
    end

    def add_neighbors(neighbors)
      @neighbors = neighbors
    end

    # XXX: Add proper route tree structure instead of neighbors?
    def neighbor_named(name)
      @neighbors.find { |route| route.name == name }
    end

    def self.for_app(app, parent_path, params)
      options = RouteOptions.new(app, parent_path, params)
      new(options.action,
          options.path,
          options.constraints,
          options.delegator,
          options.responder,
          options.exception_actions)
    end

    def respond_to_request(injector, request)
      Raptor.log("Routing #{request.path_info.inspect} to #{path.inspect}")
      injector = injector.add_route_path(request, @path)
      record = @delegator.delegate(injector)
      @responder.respond(self, record, injector)
    end

    def action_for_exception(e)
      @exception_actions.select do |exception_class, action|
        e.is_a? exception_class
      end.values.first
    end

    def match?(injector, request)
      @constraints.all? do |constraint|
        injector.call(constraint.method(:match?))
      end
    end
  end

  class HttpMethodConstraint
    def initialize(http_method)
      @http_method = http_method
    end

    def match?(http_method)
      http_method == @http_method
    end
  end

  class PathConstraint
    def initialize(path)
      @path = path
    end

    def match?(path)
      return false if components(@path).length != components(path).length
      path_component_pairs(path).all? do |route_component, path_component|
        is_variable = route_component[0] == ':'
        same_components = route_component == path_component
        is_variable || same_components
      end
    end

    def path_component_pairs(path)
      components(@path).zip(components(path))
    end

    def components(path)
      path.split('/')
    end
  end

  class NullDelegate
    def self.do_nothing
      nil
    end
  end
end

