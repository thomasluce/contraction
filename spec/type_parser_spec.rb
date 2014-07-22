require 'spec_helper'

describe Contraction::TypeLexer do
  describe '.lex' do
    it 'creates a stack of reverse-ordered tokens' do
      l = Contraction::TypeLexer
      s = l.lex('Array<Integer,{Bar}>')
      expect(s).to eq %w|> } Bar { , Integer < Array|
    end

    it 'works for very starnge type descriptions' do
      l = Contraction::TypeLexer
      s = l.lex('Hash{Integer => Array<String,Integer>}')
      expect(s).to eq %w| } > Integer , String < Array => Integer { Hash |
    end

    it "doesn't care about semanitcs (that's the parser's job)" do
      l = Contraction::TypeLexer
      expect(lambda {
        l.lex('Hash{not going to do this right')
      }).to_not raise_error
    end
  end
end

describe Contraction::TypeParser do
  it 'parses simple classes things' do
    t = Contraction::TypeParser.parse("Integer")
    expect(t.first).to be_a Contraction::TypeList
    expect(t.first.types.first).to be_a Contraction::Type
    expect(t.first.types.first.works_as_a?(Integer)).to be true
  end

  context 'hashes' do
    it 'parses explicit hashes' do
      t = Contraction::TypeParser.parse("Hash{ Integer => String }")
      h = t.first.types.first
      expect(h).to be_a Contraction::HashType
      expect(h.key_type).to be_a Contraction::TypeList
      expect(h.value_type).to be_a Contraction::TypeList
      expect(h.value_type.works_as_a? String).to be true
      expect(h.key_type.works_as_a? Integer).to be true
    end

    it 'parses simple hashes' do
      t = Contraction::TypeParser.parse("{ Integer => String }")
      h = t.first.types.first
      expect(h).to be_a Contraction::HashType
      expect(h.key_type).to be_a Contraction::TypeList
      expect(h.value_type).to be_a Contraction::TypeList
      expect(h.value_type.works_as_a? String).to be true
      expect(h.key_type.works_as_a? Integer).to be true
    end

    it 'parses hashes with compound key types' do
      t = Contraction::TypeParser.parse("{ Integer, String => String }")
      h = t.first.types.first
      expect(h).to be_a Contraction::HashType
      expect(h.key_type.works_as_a?(Integer)).to be true
      expect(h.key_type.works_as_a?(String)).to be true
    end

    it 'parses hashes with compound value types' do
      t = Contraction::TypeParser.parse("{ Integer, String => String, Integer }")
      h = t.first.types.first
      expect(h).to be_a Contraction::HashType
      expect(h.value_type.works_as_a?(Integer)).to be true
      expect(h.value_type.works_as_a?(String)).to be true
    end

    it 'parses hashes of hashes' do
      t = Contraction::TypeParser.parse("{ Integer=> Hash{ String => String }}")
      h = t.first.types.first
      expect(h).to be_a Contraction::HashType
      expect(h.key_type.works_as_a?(Integer)).to be true

      inner_hash = h.value_type.types.first
      expect(inner_hash).to be_a Contraction::HashType
      expect(inner_hash.key_type.works_as_a?(String)).to be true
      expect(inner_hash.value_type.works_as_a?(String)).to be true
    end
  end

  context 'typed containers' do
    it 'parses any old container' do
      t = Contraction::TypeParser.parse("<Integer>") # A collection of integers
      expect(t.first).to be_a Contraction::TypedContainer
      expect(t.first.type_list.works_as_a?(Integer)).to be true
    end

    it 'parses a typed container' do
      t = Contraction::TypeParser.parse("Array<Integer>") # An array of integers
      expect(t.first).to be_a Contraction::TypedContainer
      expect(t.first.type_list.works_as_a?(Integer)).to be true
      expect(t.first.class_name.works_as_a?(Array)).to be true
    end

    it 'parses a container with multiple possible types' do
      t = Contraction::TypeParser.parse("Array<Integer,String>") # An array of integers or strings
      expect(t.first).to be_a Contraction::TypedContainer
      expect(t.first.type_list.works_as_a?(Integer)).to be true
      expect(t.first.type_list.works_as_a?(String)).to be true
    end

    it 'parses a container with complex types' do
      t = Contraction::TypeParser.parse("Array<Hash{Integer => String}>") # An array of hashes
      expect(t.first).to be_a Contraction::TypedContainer
      expect(t.first.type_list.types.first).to be_a Contraction::HashType
      expect(t.first.type_list.types.first.key_type.works_as_a? Integer).to be true
      expect(t.first.type_list.types.first.value_type.works_as_a? String).to be true
    end

    it 'parses a container with nested container types' do
      t = Contraction::TypeParser.parse("Array<Array<Integer>>") # An array of arrays
      expect(t.first).to be_a Contraction::TypedContainer
      expect(t.first.type_list.types.first).to be_a Contraction::TypedContainer
    end
  end

  context 'reference types' do
    it 'parses the reference type' do
      t = Contraction::TypeParser.parse("{String}")
      expect(t.first.types.first).to be_a Contraction::ReferenceType
    end
  end

  context 'sized containers' do
    it 'works like the typed container' do
      # An array with an integer in the first place, and a string in the second.
      t = Contraction::TypeParser.parse("Array[Integer,String]")
      expect(t.first).to be_a Contraction::SizedContainer
      expect(t.first.type_list.works_as_a?(Integer)).to be true
      expect(t.first.type_list.works_as_a?(String)).to be true
    end
  end
end
