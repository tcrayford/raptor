require "rack"
require_relative "spec_helper"
require_relative "../lib/raptor"

describe Raptor::Delegator do
  let(:injector) { Raptor::Injector.new([]) }

  it "returns nil if the delegate is nil" do
    delegator = Raptor::Delegator.new(nil, :new)
    delegator.delegate(injector).should be_nil
  end

  it "returns nil if the method is nil" do
    delegator = Raptor::Delegator.new('not nil', nil)
    delegator.delegate(injector).should be_nil
  end

  it "calls the named method" do
    delegator = Raptor::Delegator.new(Hash, :new)
    delegator.delegate(injector).should == {}
  end
end

