require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

describe Raptor::Template do
  let(:presenter) { stub("presenter") }
  it "raises an error when templates access undefined methods" do
    expect do
      Raptor::Template.from_path("with_undefined_method_call_in_index/index.html.erb").render(Object.new)
    end.to raise_error(NameError,
                       /undefined local variable or method `undefined_method'/)
  end

  it "renders the template" do
    rendered = Raptor::Template.from_path("/with_no_behavior/new.html.erb").
      render(presenter)
    rendered.strip.should == "<form>New</form>"
  end

  it "inserts a slash if there isn't one on the template path" do
    rendered = Raptor::Template.from_path("with_no_behavior/new.html.erb").
      render(presenter)
    rendered.strip.should == "<form>New</form>"
  end
end

describe Raptor::Layout do
  let(:presenter) { stub }
  let(:injector) { Raptor::Injector.new([]) }

  it "renders a yielded template" do
    inner = stub(:render => 'inner')
    rendered = Raptor::Layout.from_path('spec/fixtures/layout.html.erb').
      render(inner, presenter)
    rendered.strip.should == "<div>inner</div>"
  end

  it "integrates content_for" do
    inner = Raptor::Template.from_path("../spec/fixtures/provides_content_for.html.erb")
    layout = Raptor::Layout.from_path('spec/fixtures/layout_with_content_for.html.erb')
    rendered = layout.render(inner, Raptor::ViewContext.new(presenter, injector))
    rendered.strip.should include("<script></script")
  end
end

describe Raptor::ViewContext do
  let(:injector) { Raptor::Injector.new([]) }
  it "delegates to the presenter" do
    Raptor::ViewContext.new(stub(:cheese => 'walrus'), injector).cheese.should == 'walrus'
  end

  it "stores content_for" do
    context = Raptor::ViewContext.new(stub, injector)
    context.content_for(:head) { 'what' }
    context.content_for(:head).should == 'what'
  end

  it "appends multiple content_for blocks" do
    context = Raptor::ViewContext.new(stub, injector)
    context.content_for(:head) { 'what' }
    context.content_for(:head) { 'what' }
    context.content_for(:head).should == 'whatwhat'
  end

  it "injects from the injector" do
    current_user = stub
    injector = Raptor::Injector.new([Raptor::Injectables::Fixed.new(:current_user, current_user)])
    context = Raptor::ViewContext.new(Object.new, injector)
    context.current_user.should == current_user
  end
end

describe Raptor::FindsLayouts do
  before do
    Tilt.stub(:new) do |path|
      path
    end
  end

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
    Raptor::NullLayout.render(inner, stub).should == "no wrapping"
  end
end
