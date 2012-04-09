module Raptor
  class ValidatesRoutes
    def self.validate_route_params!(params)
      raise Raptor::ConflictingRoutes if params[:redirect] && params[:render]
    end
  end

  class ConflictingRoutes < RuntimeError; end
  class BadDelegate < RuntimeError; end
end

