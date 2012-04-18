require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor/templates"

describe Raptor::Template do
  it "raises an error when templates access undefined methods" do
    presenter = Object.new
    expect do
      Raptor::Template.from_path(presenter, "with_undefined_method_call_in_index/index.html.erb").render
    end.to raise_error(NameError,
                       /undefined method `undefined_method'/)
  end

  it "renders the template" do
    presenter = stub("presenter")
    rendered = Raptor::Template.from_path(presenter,
                                       "/with_no_behavior/new.html.erb").render
    rendered.strip.should == "<form>New</form>"
  end

  it "inserts a slash if there isn't one on the template path" do
    presenter = stub("presenter")
    rendered = Raptor::Template.from_path(presenter,
                                       "with_no_behavior/new.html.erb").render
    rendered.strip.should == "<form>New</form>"
  end
end

describe Raptor::Layout do
  let(:inner) { stub(:render => 'inner', :presenter => nil) }

  it "renders a yielded template" do
    rendered = Raptor::Layout.new('spec/fixtures/layout.html.erb').
      render(inner)
    rendered.strip.should == "<div>inner</div>"
  end

  it "can use content_for in the inner layout" do
    with_content = stub(:yield_content_for => "<script></script>")
    inner.stub(:presenter => with_content)
    rendered = Raptor::Layout.new('spec/fixtures/content_for_head.html.erb').
      render(inner)
    rendered.strip.should == "<script></script>"
  end

  it "integrated content_for" do
    with_content = Raptor::ViewContext.new(stub)
    inner = Raptor::Template.from_path(with_content, "../spec/fixtures/view_with_content_for.html.erb")
    rendered = Raptor::Layout.new('spec/fixtures/content_for_head.html.erb').
      render(inner)
    rendered.strip.should == "<script></script>"
  end
end

describe Raptor::ViewContext do
  it "delegates to the presenter" do
    presenter = stub(:opens_doors? => false)
    Raptor::ViewContext.new(presenter).opens_doors?.should be_false
  end

  it "stores and yields content_for" do
    context = Raptor::ViewContext.new(stub)
    context.content_for :head do
      "what"
    end
    context.yield_content_for(:head).should == "what"
  end
end

describe Raptor::FindsLayouts do
  it "finds a layout in the path directory" do
    path = 'views/post/layout.html.erb'
    File.stub(:exist?).with(path) { true }
    Raptor::FindsLayouts.find('post').should == Raptor::Layout.new(path)
  end

  it "finds a layout in the root views directory" do
    path = 'views/layout.html.erb'
    File.stub(:exist?) { false }
    File.stub(:exist?).with(path) { true }
    Raptor::FindsLayouts.find('post').should == Raptor::Layout.new(path)
  end

  it "does not find a layout if it does not exist" do
    File.stub(:exist?) { false }
    Raptor::FindsLayouts.find('post').should == Raptor::NullLayout
  end
end

describe Raptor::NullLayout do
  it "renders the inner layout with no wrapping" do
    inner = stub(:render => "no wrapping")
    Raptor::NullLayout.render(inner).should == "no wrapping"
  end
end
