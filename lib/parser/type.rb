module Contraction
  module Parser
    class Type
      attr_reader :legal_types, :method_requirements, :length, :key_types, :value_types

      def initialize(part)
        @legal_types         = []
        @method_requirements = []
        @length              = -1
        @key_types           = []
        @value_types         = []

        parse(part)
      end

      # Checks weather or not thing is a given type.
      # @param [String] thing A string containing a type definition. For example:
      #    Array<String>
      def check(thing)
        check_types(thing) &&
        check_duck_typing(thing) &&
        check_length(thing) &&
        check_hash(thing)
      end

      private

      def parse(line)
        parse_typed_container(line) ||
          parse_duck_type(line) ||
          parse_fixed_list(line) ||
          parse_hash(line) ||
          parse_short_hash_or_reference(line) ||
          parse_regular(line)
      end

      def parse_typed_container(line)
        return unless line.include? '<'
        # It's some kind of container that can only hold certain things
        list = line.match(/\<(?<list>[^\>]+)\>/)['list']
        list.split(',').each do |type|
          @legal_types << Type.new(type.strip)
        end
        true
      end

      def parse_duck_type(line)
        return unless line =~ /^#/
        # It's a duck-typed object of some kind
        methods = line.split(",").map { |p| p.strip.gsub(/^#/,'').to_sym }
        @method_requirements += methods
        true
      end

      def parse_fixed_list(line)
        return unless line.include?('(')
        # It's a fixed-length list
        list = line.match(/\((?<list>[^\>]+)\)/)['list']
        parts = list.split(',')
        @length = parts.length
        parts.each do |type|
          @legal_types << Type.new(type.strip)
        end
        true
      end

      def parse_hash(line)
        return unless line.include? 'Hash{'
        # It's a hash with specific key-value pair types
        parts = line.match(/\{(?<key_types>.+)\s*=\>\s*(?<value_types>[^\}]+)\}/)
        @key_types = parts['key_types'].split(',').map { |t| t.include?('#') ? t.strip.gsub(/^#/, '').to_sym : t.strip.constantize }
        @value_types = parts['value_types'].split(',').map { |t| t.include?('#') ? t.strip.gsub(/^#/, '').to_sym : t.strip.constantize }
      end

      def parse_short_hash_or_reference(line)
        return unless line.include? '{'
        if parts = line.match(/\{(?<key_types>.+)\s*=\>\s*(?<value_types>[^\}]+)\}/)
          @key_types = parts['key_types'].split(',').map { |t| t.include?('#') ? t.strip.gsub(/^#/, '').to_sym : t.strip.constantize }
          @value_types = parts['value_types'].split(',').map { |t| t.include?('#') ? t.strip.gsub(/^#/, '').to_sym : t.strip.constantize }
        else
          # It's a reference to another documented type defined someplace in
          # the codebase. We can ignore the reference, and treat it like a
          # normal type.
          @legal_types << line.gsub(/\{|\}/, '').constantize
        end
        true
      end

      def parse_regular(line)
        # It's a regular-ass type.
        @legal_types << line.constantize
      end

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
