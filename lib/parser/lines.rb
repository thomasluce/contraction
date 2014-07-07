module Contraction
  module Parser
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
  end
end
