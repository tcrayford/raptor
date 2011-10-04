require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/validation"

describe "route validation" do
  context "the full route" do
    it "rejects routes with exactly the same path and redirects" do
      redirects = {:redirect => :index}
      route = stub(:action => :index, :params => redirects)
      conflicting = stub(:action => :index, :params => redirects)
      routes = [route, conflicting]
      expect do
        Raptor::ValidatesRoutes.validate!(routes)
      end.to raise_error(Raptor::ConflictingRoutes)
    end

    it "doesn't reject routes that have different redirects" do
      with_redirects = stub(:action => :update,
                            :params => {:ValidationError => :edit})
      without_redirects =  stub(:action => :update, :params => {})
      routes = [with_redirects, without_redirects]
      Raptor::ValidatesRoutes.validate!(routes)
    end
  end

  context "the route params" do
    it "rejects routes with both a render and a redirect" do
      redirect_and_render = {:redirect => :index, :render => :show}
      expect do
        validate_params(redirect_and_render)
      end.to raise_error(Raptor::ConflictingRoutes)
    end

    it "does not reject route params with just a redirect" do
      just_redirect = {:redirect => :index}
      validate_params(just_redirect)
    end

    it "does not reject route params with just a render" do
      just_render = {:render => :index}
      validate_params(just_render)
    end

    it "does not reject empty route params" do
      validate_params({})
    end

    def validate_params(params)
      Raptor::ValidatesRoutes.validate!([stub(:params => params)])
    end
  end
end
