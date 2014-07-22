# FIXME: There is an aweful lot of knowledge about which kind of TypedLine is
# being used scattered around the system. I need to encapsulate that better;
# the abstractions are leaking!
module Contraction
  module Parser
    class TypedLine
      attr_reader :type, :contract, :message, :types
      attr_writer :contract

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

      def evaluate_in_context(context, method_name, value)
        return if !contract || contract.to_s.strip == ''
        raise contract_message(value, method_name) unless eval(contract, context)
      end

      def contract_message(value=nil, method_name=nil)
        raise 'Not Implemented'
      end
    end

    class ParamLine < TypedLine
      attr_reader :name

      def initialize(args={})
        super
        @name = args[:name]
      end

      def contract_message(value, method_name=nil)
        "#{name} (#{message}) must fullfill #{contract.inspect}, but is #{value.inspect}"
      end
    end

    class ReturnLine < TypedLine
      def name
        nil
      end

      def contract_message(value, method_name=nil)
        "Return value of #{method_name} (#{message}) must fullfill #{contract.inspect}, but is #{value}"
      end
    end
  end
end
