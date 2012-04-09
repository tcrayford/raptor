require "raptor"

describe Raptor::BuildsRoutes do
  let(:app) { stub(:app) }
  it "errors when asked to create guess a presenter for a root URL like GET /" do
    expect do
      Raptor::BuildsRoutes.new(app).index
    end.to raise_error(Raptor::CantInferModulePathsForRootRoutes)
  end
end

