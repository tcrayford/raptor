require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/responders"

describe Raptor::Template do
  it "raises an error when templates access undefined methods" do
    presenter = Object.new
    File.stub(:new) { StringIO.new("{{undefined_method}}") }

    expect do
      Raptor::Template.new(presenter, "/posts/show.html.mustache").render
    end.to raise_error(Mustache::ContextMiss,
                       /Can't find undefined_method/)
  end

  it "renders the template" do
    presenter = stub("presenter")
    rendered = Raptor::Template.new(presenter,
                                "/with_no_behavior/new.html.mustache").render
    rendered.strip.should == "<form>New</form>"
  end

  it "inserts a slash if there isn't one on the template path" do
    presenter = stub("presenter")
    rendered = Raptor::Template.new(presenter,
                                  "with_no_behavior/new.html.mustache").render
    rendered.strip.should == "<form>New</form>"
  end
end

describe Raptor::Layout do
  it "renders a layout with the inner content" do
    template = stub(:render => "inner")
    File.stub(:new) { StringIO.new("<div>{{yield}}</div>") }
    rendered = Raptor::Layout.new('posts').render(template)
    rendered.strip.should == "<div>inner</div>"
  end
end

describe Raptor::NullLayout do
  it "just renders the inner content" do
    template = stub(:render => "inner")
    Raptor::NullLayout.new.render(template).should == "inner"
  end
end

describe Raptor::FindsLayouts do
  describe 'finding layouts' do
    it "finds layouts in the path directory" do
      path = 'views/posts/layout.html.mustache'
      File.stub(:exists?).with(path) { true }
      Raptor::FindsLayouts.find('posts').should == Raptor::Layout.new(path)
    end

    it "finds layouts in a directory above the path directory" do
      path = 'views/layout.html.mustache'
      File.stub(:exists?) { false }
      File.stub(:exists?).with(path) { true }
      Raptor::FindsLayouts.find('posts').should == Raptor::Layout.new(path)
    end

    it "returns no layout if it cannot find one" do
      File.stub(:exists?) { false }
      Raptor::FindsLayouts.find('posts').should == Raptor::NullLayout.new
    end
  end
end
