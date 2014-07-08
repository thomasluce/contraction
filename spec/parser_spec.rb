require 'spec_helper'
require 'parser'

describe Contraction::Parser do
  def parse(string)
    Contraction::Parser.parse_line(string)
  end

  context 'parsing' do
    describe 'param strings' do
      it 'parses a simple, typed param' do
        p = parse('# @param [Fixnum] foo foo is a number')
        expect(p).to be_a Contraction::Parser::ParamLine
      end
    end
  end

  context 'params' do
    describe 'types' do
      it 'verifies simple object types' do
        p = parse('# @param [Fixnum] foo foo is a number')
        expect(p.valid?(2)).to be true
        expect(p.valid?('foobar')).to be false
      end

      it 'verifies simple collection types' do
        p = parse('# @param [Array<Fixnum>] foo foo is a number')
        expect(p.valid?(2)).to be false
        expect(p.valid?('foobar')).to be false
        expect(p.valid?([2, 1])).to be true
        expect(p.valid?([2, :thing])).to be false
      end

      it 'verifies duck-typed objects' do
        class Duck
          def quack
          end
        end

        p = parse('# @param [#quack] foo foo is a duck')

        expect(p.valid?(Duck.new)).to be true
        expect(p.valid?(Object.new)).to be false
      end

      it 'verifies a list of duck-typed objects' do
        class Duck
          def quack
          end

          def waddle
          end
        end

        class Goose
          def honk
          end

          def waddle
          end
        end

        p = parse('# @param [#waddle,#quack] foo foo is a duck')
        expect(p.valid?(Duck.new)).to be true
        expect(p.valid?(Goose.new)).to be false
      end

      it 'verifies a collection with multiple possible types' do
        p = parse('# @param [Array<Fixnum,String>] foo foo is bar')
        expect(p.valid?([1])).to be true
        expect(p.valid?(['1'])).to be true
        expect(p.valid?(['1', 1])).to be true
        expect(p.valid?(['1', :sym])).to be false
      end

      it 'verifies a fixed-length collection' do
        p = parse('# @param [Array(Fixnum, Fixnum)] foo foo is bar')
        expect(p.valid?([1,1])).to be true
        expect(p.valid?([1])).to be false
        expect(p.valid?([1, 1, 1])).to be false
      end

      it 'verifies a hash in long-hand' do
        p = parse('# @param [Hash{Symbol => String, Fixnum}] foo foo is bar')
        expect(p.valid?({ foo: 1 })).to be true
        expect(p.valid?({ foo: 'one' })).to be true
        expect(p.valid?({ 'foo' => 1 })).to be false
        expect(p.valid?({ foo: :bar })).to be false
      end

      it 'verifies a hash in short-hand' do
        p = parse('# @param [{ String => Fixnum }] foo foo is bar')
        expect(p.valid?({ foo: 1 })).to be false
        expect(p.valid?({ "foo" => 1 })).to be true
      end

      it 'verifies hashes that use duck-typing for key and value types' do
        class Foo
          def foo
          end
        end

        class Bar
          def bar
          end
        end

        p = parse('# @param [{ #foo => #bar }] foo foo is bar')
        expect(p.valid?({ Foo.new => Bar.new })).to be true
        expect(p.valid?({ foo: :bar })).to be false
      end
    end
  end
end
