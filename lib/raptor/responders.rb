require "mustache"

module Raptor
  class PlaintextResponder
    def initialize(text)
      @text = text
    end

    def respond(route, subject, injector)
      Rack::Response.new(@text)
    end
  end

  class RedirectResponder
    def initialize(app_module, target_route_name)
      @app_module = app_module
      @target_route_name = target_route_name
    end

    def respond(route, subject, injector)
      response = Rack::Response.new
      path = route.neighbor_named(@target_route_name).path
      if subject
        path = path.gsub(/:\w+/) do |match|
          # XXX: Untrusted send
          subject.send(match.sub(/^:/, '')).to_s
        end
      end
      redirect_to(response, path)
      response
    end

    def target_path
      @route_neighbors.select do |route|
        route.name == @target_route_name
      end
    end

    def redirect_to(response, location)
      Raptor.log("Redirecting to #{location}")
      response.status = 302
      response["Location"] = location
    end
  end

  class TemplateResponder
    def initialize(app_module, presenter_name, template_path)
      @app_module = app_module
      @presenter_name = presenter_name
      @template_path = template_path
    end

    def respond(route, subject, injector)
      presenter = create_presenter(subject, injector)
      Rack::Response.new(render(presenter))
    end

    def render(presenter)
      Template.render(presenter, template_path)
    end

    def template_path
      "#{@template_path}.html.mustache"
    end

    def create_presenter(subject, injector)
      injector = injector.add_subject(subject)
      injector.call(presenter_class.method(:new))
    end

    def presenter_class
      constant_name = Raptor::Util.camel_case(@presenter_name)
      @app_module::Presenters.const_get(constant_name)
    end
  end

  class ActionTemplateResponder
    def initialize(app_module, presenter_name, parent_path, template_name)
      @app_module = app_module
      @presenter_name = presenter_name
      @parent_path = parent_path
      @template_name = template_name
    end

    def respond(route, subject, injector)
      responder = TemplateResponder.new(@app_module,
                                        @presenter_name,
                                        template_path)
      responder.respond(route, subject, injector)
    end

    def template_path
      # XXX: Support multiple template directories
      "#{@parent_path}/#{@template_name}"
    end
  end

  class Template < Mustache
    @raise_on_context_miss = true
    def initialize(presenter, template_path)
      @presenter = presenter
      @template_path = template_path
    end

    def self.render(presenter, template_path)
      new(presenter, template_path).render
    end

    def template
      File.new(full_template_path).read
    end

    def full_template_path
      template_path = @template_path
      template_path = "/#{template_path}" unless template_path =~ /^\//
      "views#{template_path}"
    end

    def method_missing(method_name, *args, &block)
      @presenter.send(method_name)
    end

    def respond_to?(method_name)
      @presenter.respond_to?(method_name)
    end
  end
end

