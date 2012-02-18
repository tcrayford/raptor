require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/responders"

describe Raptor::Template do
  it "raises an error when templates access undefined methods" do
    presenter = Object.new
    File.stub(:new) { StringIO.new("{{undefined_method}}") }

    expect do
      Raptor::Template.render(presenter, "/posts/show.html.mustache")
    end.to raise_error(Mustache::ContextMiss,
                       /Can't find undefined_method/)
  end

  it "renders the template" do
    presenter = stub("presenter")
    rendered = Raptor::Template.render(presenter,
                                       "/with_no_behavior/new.html.mustache")
    rendered.strip.should == "<form>New</form>"
  end

  it "inserts a slash if there isn't one on the template path" do
    presenter = stub("presenter")
    rendered = Raptor::Template.render(presenter,
                                       "with_no_behavior/new.html.mustache")
    rendered.strip.should == "<form>New</form>"
  end
end

