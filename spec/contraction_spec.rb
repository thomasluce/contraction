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
        }.should raise_error(ArgumentError, "Return value of foobar (A string, you say?! ) must fullfill \"result.include?('foobar')\", but is \"no foo or bar here\"")
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
        }.should raise_error(ArgumentError, 'Return value of foobar (A message with no type here ) must fullfill "result.to_s.include?(\"foobar\")", but is :no_foo_or_bar_in_symbol')
      end
    end
  end

  describe 'method arguments'
  # TODO: back-fill these puppies.
end
