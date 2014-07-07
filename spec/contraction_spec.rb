require 'spec_helper'

describe Contraction do
  describe 'return values' do
    context 'when not defined' do
      before do
        class NoReturnClass
          ##
          # Some documentation
          def foobar
            "a return"
          end

          include Contraction
        end
      end

      it 'does not raise an error' do
        lambda  {
          NoReturnClass.new.foobar
        }.should_not raise_error
      end

      it "doesn't stop any return value" do
        NoReturnClass.new.foobar.should == "a return"
      end
    end

    context 'when defined without a type' do
      before do
        class ReturnNoType
          ##
          # Some docs
          # @return All kinds of return
          def foobar
            "A return"
          end

          include Contraction
        end
      end

      it "doesn't raise an error" do
        lambda {
          ReturnNoType.new.foobar
        }.should_not raise_error
      end

      it "should allow the return to pass through" do
        ReturnNoType.new.foobar.should == "A return"
      end
    end

    context 'when defined with a type' do
      before do
        class ReturnType
          ##
          # Some docs
          # @return [String] it returns a string
          def foobar(thing_to_return)
            thing_to_return
          end

          include Contraction
        end
      end

      it "doesn't raise an error" do
        lambda {
          ReturnType.new.foobar("foobar")
        }.should_not raise_error
      end

      it "allows correctly typed-values to return normally" do
        ReturnType.new.foobar("foobar").should == "foobar"
      end

      it "raises an error if the return type is wrong" do
        lambda {
          ReturnType.new.foobar(:thing)
        }.should raise_error(ArgumentError, "Return value of foobar must be a String")
      end
    end

    context 'when defined with a type and a contract' do
      before do
        class ReturnWithTypeAndContract
          ##
          # Some docs
          # @return [String] A string, you say?! { return.include?('foobar') }
          def foobar(thing)
            return thing
          end

          include Contraction
        end
      end

      it "doesn't raise an error" do
        lambda {
          ReturnWithTypeAndContract.new.foobar("foobar")
        }.should_not raise_error
      end

      it "allows correctly typed and vetted values through" do
        lambda {
          ReturnWithTypeAndContract.new.foobar("foobar string")
        }.should_not raise_error
      end

      it "raises an error on incorrect types" do
        lambda {
          ReturnWithTypeAndContract.new.foobar(:foobar_sym)
        }.should raise_error(ArgumentError, "Return value of foobar must be a String")
      end

      it "raises an error on bad contract enforcement" do
        lambda {
          ReturnWithTypeAndContract.new.foobar("no foo or bar here")
        }.should raise_error
      end
    end

    context 'when defined with no type, but a contract' do
      before do
        class ReturnWithContract
          ##
          # Some kind of docs
          # @return A message with no type here { return.to_s.include?("foobar") }
          def foobar(thing)
            return thing
          end

          include Contraction
        end
      end

      it "doesn't raise an error" do
        lambda {
          ReturnWithContract.new.foobar("foobar")
        }.should_not raise_error
      end

      it "allows values that match the contract through" do
        lambda {
          ReturnWithContract.new.foobar("string with foobar all up in it")
        }.should_not raise_error
      end

      it "raises an error on non-contract-matching values" do
        lambda {
          ReturnWithContract.new.foobar(:no_foo_or_bar_in_symbol)
        }.should raise_error
      end
    end
  end

  describe 'method arguments' do
    context 'with no definition' do
      before do
        class NoParams
          ##
          # Some docs
          def foobar(foo,bar)
          end

          include Contraction
        end
      end

      it "doesn't explode" do
        lambda { NoParams.new.foobar(1,2) }.should_not raise_error
      end

      it "allows the method to be called however you like" do
        np = NoParams.new
        lambda {
          np.foobar(1,2)
          np.foobar(:foo, :bar)
          np.foobar('foo', nil)
        }.should_not raise_error
      end
    end

    context 'with type definition' do
      before do
        class ParamType
          ##
          # Some docs
          # @param [String] foo Must be a string
          def foobar(foo)
          end

          include Contraction
        end
      end

      it "doesn't explode" do
        lambda { ParamType.new.foobar("String") }.should_not raise_error
      end

      it 'raises an error if the wrong type is passed' do
        lambda {
          ParamType.new.foobar(:not_a_string)
        }.should raise_error(ArgumentError, "foo (:not_a_string) must be a String")
      end

      it 'allows the call with the correct type' do
        lambda {
          ParamType.new.foobar('string, it is')
        }.should_not raise_error(ArgumentError)
      end
    end

    context 'with type and contract' do
      before do
        class ParamTypeAndContract
          ##
          # Some doc
          # @param [String] foo Should be a string that { foo.include?('bar') }
          def foobar(foo)
          end

          include Contraction
        end
      end

      it "doesn't explode" do
        lambda { ParamTypeAndContract.new.foobar("bar") }.should_not raise_error
      end

      it "raises an error if the contract is not matched" do
        lambda { ParamTypeAndContract.new.foobar("not b-a-r") }.should raise_error
      end

      it "raises an error if the type is not matched" do
        lambda { ParamTypeAndContract.new.foobar(:bar) }.should raise_error(ArgumentError, "foo (:bar) must be a String")
      end

      it "allows the method call if the contract and type are matched" do
        lambda { ParamTypeAndContract.new.foobar("totally has bar in it") }.should_not raise_error
      end
    end
  end
end
