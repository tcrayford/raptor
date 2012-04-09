require "raptor"

describe Raptor::BuildsRoutes do
  let(:app) { stub(:app) }
  it "errors when asked to create guess a presenter for a root URL like GET /" do
    expect do
      Raptor::BuildsRoutes.new(app).index
    end.to raise_error(Raptor::CantInferModulePathsForRootRoutes)
  end

  it "errors if you give it too many arguments" do
    expect do
      Raptor::BuildsRoutes.new(app).index(1,2,3,4)
    end.to raise_error(Raptor::BadRouteSyntax)
  end
end

