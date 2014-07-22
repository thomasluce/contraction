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

          # Do something on the class
          # @return [Hash{Integer => Array<String>}]
          def barbaz
            { 1 => ['foo', 'bar'] }
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
        }.should raise_error(ArgumentError)
      end

      context 'with a complex type' do
        it 'should not break when the type is correct' do
          lambda { ReturnType.new.barbaz }.should_not raise_error
        end
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
        }.should raise_error
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
        }.should raise_error(ArgumentError)
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
        lambda { ParamTypeAndContract.new.foobar(:bar) }.should raise_error
      end

      it "allows the method call if the contract and type are matched" do
        lambda { ParamTypeAndContract.new.foobar("totally has bar in it") }.should_not raise_error
      end
    end

    describe 'optional arguments' do
    end

    describe 'blocks' do
    end
  end

  describe 'class methods' do
    before do
      class WithClassMethods
        ##
        # This is some documentation
        # @param [String] foo is a string { foo.to_s.include?('bar') }
        # @return [Fixnum] the length of the string
        def self.foo(foo)
          foo.length
        end

        include Contraction
      end
    end

    it "doens't explode" do
      lambda { WithClassMethods.foo("bar") }.should_not raise_error
    end

    it "applies contracts and type checks" do
      lambda { WithClassMethods.foo("no b.a.r") }.should raise_error
    end
  end

  describe 'class methods' do
    class ClassMethods
      # Do some stuff
      # @return [ClassMethods] self
      def self.foobar
      end

      # @return [ClassMethods] self
      def self.barbaz
        self.allocate
      end

      include Contraction
    end

    it 'should work' do
      expect(lambda { ClassMethods.foobar }).to raise_error
      expect(lambda { ClassMethods.barbaz }).to_not raise_error
    end
  end

  describe 'instance gathering methods' do
    class MethodTestingClass
      def self.foobar
      end

      def foo
      end

      private

      def bar
      end

      # Interestingly, self.barbaz doesn't make it actually private, but class
      # << self; def barbaz; end; end; will. It's because def object.thing
      # defines a method on object (in this case self), and so is "re-opening"
      # the class, making it public.
      def self.barbaz
      end
      private_class_method :barbaz
    end

    describe '.instance_methods_for' do
      it 'returs only public methods' do
        expect(Contraction.instance_methods_for(MethodTestingClass)).to_not include :bar
      end

      it 'returns instance methods' do
        expect(Contraction.instance_methods_for(MethodTestingClass)).to include :foo
      end

      it 'does not return class methods' do
        expect(Contraction.instance_methods_for(MethodTestingClass)).to_not include :foobar
      end
    end

    describe '.class_methods_for' do
      it 'returns only public methods' do
        expect(Contraction.class_methods_for(MethodTestingClass)).to_not include :barbaz
      end

      it 'does not return instance methods' do
        expect(Contraction.class_methods_for(MethodTestingClass)).to_not include :foo
      end

      it 'returns class methods' do
        expect(Contraction.class_methods_for(MethodTestingClass)).to include :foobar
      end
    end

    describe '.methods_for' do
      it 'returns a hash containing both instance and class methods' do
        expected_hash = {
          class: Contraction.class_methods_for(MethodTestingClass),
          instance: Contraction.instance_methods_for(MethodTestingClass)
        }
        expect(Contraction.methods_for(MethodTestingClass)).to eq expected_hash
      end
    end
  end
end
