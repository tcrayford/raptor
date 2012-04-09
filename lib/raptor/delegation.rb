module Raptor
  class Delegator
    def initialize(delegate, method_name)
      @delegate = delegate
      @method_name = method_name
    end

    def delegate(injector)
      return nil unless @delegate && @method_name
      Raptor.log("Delegating to #{@delegate.inspect} with #{@method_name.inspect}")
      record = injector.call(delegate_method)
      Raptor.log("Delegate returned #{record.inspect}")
      record
    end

    def delegate_method
      @delegate.method(@method_name)
    end
  end
end

