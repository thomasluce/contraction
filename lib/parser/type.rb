module Contraction
  module Parser
    class Type
      attr_reader :legal_types, :method_requirements, :length, :key_types, :value_types

      # FIXME: There is still a lot of ugly in this method...
      def initialize(part)
        @legal_types         = []
        @method_requirements = []
        @length              = -1
        @key_types           = []
        @value_types         = []

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
        elsif part =~ /^#/
          # It's a duck-typed object of some kind
          methods = part.split(",").map { |p| p.strip.gsub(/^#/,'').to_sym }
          @method_requirements += methods
        elsif part.include? '('
          # It's a fixed-length list
          list = part.match(/\((?<list>[^\>]+)\)/)['list']
          parts = list.split(',')
          @length = parts.length
          parts.each do |type|
            @legal_types << Type.new(type.strip)
          end
        elsif part.include? 'Hash{'
          # It's a hash with specific key-value pair types
          parts = part.match(/\{(?<key_types>.+)\s*=\>\s*(?<value_types>[^\}]+)\}/)
          @key_types = parts['key_types'].split(',').map { |t| t.include?('#') ? t.strip.gsub(/^#/, '').to_sym : t.strip.constantize }
          @value_types = parts['value_types'].split(',').map { |t| t.include?('#') ? t.strip.gsub(/^#/, '').to_sym : t.strip.constantize }
        elsif part.include? '{'
          if parts = part.match(/\{(?<key_types>.+)\s*=\>\s*(?<value_types>[^\}]+)\}/)
            @key_types = parts['key_types'].split(',').map { |t| t.include?('#') ? t.strip.gsub(/^#/, '').to_sym : t.strip.constantize }
            @value_types = parts['value_types'].split(',').map { |t| t.include?('#') ? t.strip.gsub(/^#/, '').to_sym : t.strip.constantize }
          else
            # It's a reference to another documented type defined someplace in
            # the codebase. We can ignore the reference, and treat it like a
            # normal type.
            @legal_types << part.gsub(/\{|\}/, '').constantize
          end
        else
          # It's a regular-ass type.
          @legal_types << part.constantize
        end
      end

      # Check weather or not thing is a given type.
      def check(thing)
        check_types(thing) &&
        check_duck_typing(thing) &&
        check_length(thing) &&
        check_hash(thing)
      end

      private

      def check_hash(thing)
        return true if @key_types.empty? or @value_types.empty?
        return false unless thing.is_a?(Hash)
        thing.keys.all? do |k|
          @key_types.any? { |kt| kt.is_a?(Symbol) ? k.respond_to?(kt) : k.is_a?(kt) }
        end &&
        thing.values.all? do |v|
          @value_types.any? { |vt| vt.is_a?(Symbol) ? v.respond_to?(vt) : v.is_a?(vt) }
        end
      end

      def check_length(thing)
        return true if @length == -1
        thing.length == @length
      end

      def check_duck_typing(thing)
        return true if @method_requirements.empty?
        @method_requirements.all? do |m|
          thing.respond_to? m
        end
      end

      def check_types(thing)
        return true if @legal_types.empty?
        if thing.is_a? Enumerable
          types = @legal_types.map { |t| t.respond_to?(:legal_types) ? t.legal_types : t }.flatten
          return thing.all? { |th| types.include?(th.class) }
        else
          @legal_types.any? do |t|
            if t.is_a?(Contraction::Parser::Type)
              #  Given the fact that we check enumerables above, we should never be here.
              next false
            end
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
