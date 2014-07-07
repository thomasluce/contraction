require 'spec_helper'
require 'parser'

describe Contraction::Parser do
  context 'parsing' do
    describe 'param strings' do
      it 'parses a simple, typed param' do
        p = Contraction::Parser.parse('# @param [Fixnum] foo foo is a number')
        expect(p).to be_a Contraction::Parser::ParamLine
      end
    end
  end

  context 'params' do
    describe 'types' do
      it 'verifies simple object types' do
        p = Contraction::Parser.parse('# @param [Fixnum] foo foo is a number')
        expect(p.valid?(2)).to be true
        expect(p.valid?('foobar')).to be false
      end

      it 'verifies simple collection types' do
        p = Contraction::Parser.parse('# @param [Array<Fixnum>] foo foo is a number')
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

        p = Contraction::Parser.parse('# @param [#quack] foo foo is a duck')

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

        p = Contraction::Parser.parse('# @param [#waddle,#quack] foo foo is a duck')
        expect(p.valid?(Duck.new)).to be true
        expect(p.valid?(Goose.new)).to be false
      end
    end
  end

  context 'parsing types' do
    describe 'types' do
      describe 'simple object types' do
        it 'parses a simple object to a simple type' do
          param = Contraction::Parser::ParamLine.new(type: 'Fixnum')
          expect(param.types.length).to eq 1
        end

        it 'parses a simple object to the correct type' do
          param = Contraction::Parser::ParamLine.new(type: 'Fixnum')
          p = param.types.first
          expect(p.legal_types.first).to be Fixnum
        end
      end

      describe 'duck-typed objects' do
        it 'parses a duck-type method signature' do
          param = Contraction::Parser::ParamLine.new(type: '#quack')
          p = param.types.first
          expect(p.method_requirements).to eq [:quack]
        end

        it 'parses a list of duck-typed things' do
          param = Contraction::Parser::ParamLine.new(type: '#quack, #waddle')
          p = param.types.first
          expect(p.method_requirements).to eq [:quack, :waddle]
        end
      end

      describe 'collection types' do
        # NOTE: For now I'm not differentiating between collection types;
        # everything is an array as far as Contraction goes. So, make sure to
        # define good contracts for things that depend on the behavior of Sets
        # or Lists, etc. Future improvements coming.
        it 'parses a simple collection with a simple type' do
          param = Contraction::Parser::ParamLine.new(type: 'Array<Fixnum>')
          p = param.types.first
          expect(p.legal_types.first).to be_a Contraction::Parser::Type
          expect(p.legal_types.first.legal_types.length).to eq 1
          expect(p.legal_types.first.legal_types.first).to be Fixnum
        end
      end
    end
  end
end
