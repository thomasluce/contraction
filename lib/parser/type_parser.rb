module Contraction
  # The lexer scans the input, creating a stack of tokens that can be used
  # to then figure out our parse tree.
  class TypeLexer
    TOKENS = [
      /^Hash/,
      /^=>/,
      /^\{/, /^\}/,
      /^\[/, /^\]/,
      /^\(/, /^\)/,
      /^</, /^>/,
      /^,/,
      /^#/,
      /(H(?!ash))?[^=\{\[\(<>\)\]\},#]+/
    ]

    def self.lex(text)
      stack = []
      while text.length > 0
        changed = false

        TOKENS.each do |r|
          if m = text.match(r)
            stack << m[0].strip
            text.sub! r, ''
            changed = true
            break
          end
        end

        raise "Unknown token found at #{text}" unless changed
      end

      stack.reverse
    end
  end

  class Type
    attr_reader :klass
    def initialize(klass)
      @klass = klass
    end

    def works_as_a?(thing)
      thing == klass
    end
  end

  class TypeList
    attr_reader :types
    def initialize(things)
      @types = things.flatten
    end

    def works_as_a?(thing)
      types.any? { |t| t.works_as_a? thing }
    end
  end

  class HashType
    attr_reader :key_type, :value_type
    def initialize(key_type, value_type)
      @key_type = key_type
      @value_type = value_type
    end
  end

  class TypedContainer
    attr_reader :type_list, :class_name

    def initialize(class_type, type_list)
      @type_list  = type_list
      @class_name = class_type
    end

    def works_as_a?(thing)
      type_list.works_as_a? thing
    end
  end

  class ReferenceType
    attr_reader :klass
    def initialize(klass)
      @klass = klass
    end
  end

  class SizedContainer
  end

  class TypeParser
    def self.parse(string)
      @stack = TypeLexer.lex(string)

      # We are going to walk though this one at a time, popping off the
      # end, and seeing if the list of thing we have so far matches any
      # known rules, being as greedy as possible.
      # TODO: Make sure that the ordering is correct; I want to get a hash
      # before other types, for example.
      things = [:typed_container, :type_list, :reference, :hash, :sized_container]
      something_happened = false
      data = []
      begin
        something_happened = false
        things.each do |t|
          thing = send(t)
          if thing
            data << thing
            something_happened = true
          end
        end
      end while something_happened
      data.flatten
    end

    # A class name is anything that has a capitol first-letter
    def self.class_name
      thing = @stack.pop
      return nil if thing.nil?
      if thing[0] =~ /^[A-Z]/
        return Type.new(thing.constantize)
      else
        @stack.push thing
        return nil
      end
    end

    # A type is either hash, or any class-name like thing
    def self.type
      reference || hash || typed_container || class_name
    end

    # A type-list is a Type, optionally followed by a comma and another
    # type-list
    def self.type_list
      things = []
      things << type
      return nil if things.first.nil?

      things << @stack.pop
      if things.last != ','
        @stack.push things.pop
        return TypeList.new things
      end
      things.pop # Remove the ',' from the list

      things << type_list
      TypeList.new(things)
    end

    # A hash starts with an optional "Hash", and this then followed by an
    # opening {, followed by a type-list, followed by a fat arrow ("=>"),
    # followed by another type-list, followed by a closing curly brace
    # ("}")
    def self.hash
      things = []
      things << @stack.pop
      if things.first != 'Hash' && things.first != '{'
        things.size.times { @stack.push things.pop }
        return nil
      end

      if things.first == 'Hash'
        things << @stack.pop
      end

      if things.last != '{'
        things.size.times { @stack.push things.pop }
        return nil
      end

      # Get the first type
      key_type = type_list
      if !key_type
        things.size.times { @stack.push things.pop }
        return nil
      else
        things << key_type
      end

      # And the arrow
      things <<  @stack.pop
      if things.last != '=>'
        things.size.times { @stack.push things.pop }
        return nil
      end

      # And the value type
      value_type = type_list
      if !value_type
        things.size.times { @stack.push things.pop }
        return nil
      end

      # Finally, the colosing brace
      things << @stack.pop
      if things.last != '}'
        things.size.times { @stack.push things.pop }
        return nil
      end

      HashType.new(key_type, value_type)
    end

    # A typed container is an optional class type, followed by a '<', followed
    # by a type list, followed by a '>'
    def self.typed_container
      class_type = class_name

      bracket = @stack.pop
      if bracket.nil?
        if class_type
          @stack.push class_type.klass.to_s
        end
        return nil
      end
      if bracket != '<'
        @stack.push bracket

        if class_type
          @stack.push class_type.klass.to_s
        end
        return nil
      end

      types = type_list
      if !types
        @stack.push bracket

        if class_type
          @stack.push class_type.klass.to_s
        end
        return nil
      end

      bracket2 = @stack.pop
      if bracket2.nil? || bracket2 != '>'
        raise "Expected '>', got #{bracket2}: #{@stack.inspect}"
      end

      TypedContainer.new(class_type, types)
    end

    # A reference is a "{" followed by a type, followed by a "}"
    def self.reference
      b = @stack.pop
      return nil if b.nil?
      if b != '{'
        @stack.push b
        return nil
      end

      t = class_name
      if !t
        @stack.push b
        return nil
      end

      b2 = @stack.pop
      if b2.nil? || b2 != '}'
        @stack.push b2 if b2
        @stack.push t.klass.to_s
        @stack.push b
        return nil
      end

      return ReferenceType.new t
    end

    def self.sized_container
    end
  end
end
