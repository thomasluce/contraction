require 'string'

module Contraction
  module Parser
    RETURN_LINE_REGEX = /^#\s*@return\s+(?<type>\[[^\]]+\])?\s*(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/
    PARAM_LINE_REGEX  = /^#\s*@param\s+(?<type>\[[^\]]+\])?\s*(?<name>[^\s]+)\s+(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/

    def self.parse(line)
      if m = line.match(PARAM_LINE_REGEX)
        args = {
          type: m['type'].to_s.gsub(/(\[|\])/, ''),
          name: m['name'],
          message: m['message'],
          contract: (m['contract'] || 'true').gsub(/(^\{)|(\}$)/, '')
        }

        return ParamLine.new(args)
      else
        raise 'Should not be here'
      end
    end

    class TypedLine
      attr_reader :type, :contract, :message, :types

      def initialize(args={})
        @type     = args[:type]
        @contract = args[:contract]
        @message  = args[:message]
        parse_type
      end

      def parse_type
        parts = type.split(/(\>|\}|\)),/)
        @types = []
        parts.each do |part|
          @types << Type.new(part)
        end
      end

      def valid?(*value)
        @types.each_with_index.all? do |t, i|
          t.check(value[i])
        end
      end
    end

    class ParamLine < TypedLine
      attr_reader :name

      def initialize(args={})
        super(args)
        @name = args[:name]
      end
    end

    class ReturnLine < TypedLine
    end

    class Type
      attr_reader :legal_types

      def initialize(part)
        @legal_types         = []
        @method_requirements = []
        @length              = -1

        # NOTE these come from the YardDoc page on types:
        # A bunch of regular types and a constant:
        # Fixnum, Foo, Object, true
        # A duck-typed Object
        # #read
        # An array of various objects
        # Array<String, Symbol, #read>
        # A collection type other than an Array
        # Set<Number>
        # An fixed-size array of specific objects
        # Array(String, Symbol)
        # A Hash with one key type and a few value types
        # Hash{String => Symbol, Number}
        # A complex example showing a possibility of many different types
        # Array<Foo, Bar>, List(String, Symbol, #to_s), {Foo, Bar => Symbol, Number}
        # Finally, some shorthands for collections and hashes
        # <String, Symbol>, (String, Symbol), {Key=>Value}

        if part.include? '<'
          # It's some kind of container that can only hold certain things
          list = part.match(/\<(?<list>[^\>]+)\>/)['list']
          list.split(',').each do |type|
            @legal_types << Type.new(type.strip)
          end
        elsif part.include? '#'
          # It's a duck-typed object of some kind
          @method_requirements << part.gsub(/^#/, '').to_sym
        elsif part.include? '('
          # It's a fixed-length list
          list = part.match(/\((?<list>[^\>]+)\)/)['list']
          parts = list.split(',')
          @length = parts.length
          list.each do |type|
            @legal_types << Type.new(type.strip)
          end
        elsif part.include? 'Hash{'
          # It's a hash with specific key-value pair types
          # TODO: do that
        elsif part.include? '{'
          # It could be a hash (look for rockets), or it could be a Struct-type.
          # TODO: do this
        else
          # It's a regular-ass type.
          @legal_types << part.constantize
        end
      end

      # Check weather or not thing is a given type.
      def check(thing)
        @legal_types.any? do |t|
          if t.is_a?(Contraction::Parser::Type)
            thing.is_a?(Enumerable) && t.check(thing)
          else
            if thing.is_a?(Enumerable)
              thing.all? { |th| th.is_a?(t) }
            else
              thing.is_a?(t)
            end
          end
        end
      end
    end
  end
end
