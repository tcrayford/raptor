module Raptor
  class ValidatesRoutes
    def self.validate!(routes)
      new(routes).validate!
    end

    def initialize(routes)
      @routes = routes
    end

    def validate!
      validate_redirects
      validate_render_and_redirect
    end

    def validate_redirects
      raise Raptor::ConflictingRoutes if pairs(@routes).any? do |a, b|
        same_actions?(a,b) && same_params?(a,b)
      end
    end

    def validate_render_and_redirect
      @routes.each do |route|
        params = route.params
        raise Raptor::ConflictingRoutes if params[:redirect] && params[:render]
      end
    end

    def pairs(routes)
      routes.product(routes).select do |x,y|
        x != y
      end
    end

    def same_actions?(a,b)
      a.action == b.action
    end

    def same_params?(a,b)
      a.params == b.params
    end

  end

  class ConflictingRoutes < RuntimeError; end
end

