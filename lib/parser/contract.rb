module Contraction
  module Parser
    class Contract
      attr_reader :rules, :mod

      # @params [Array<TypedLine>] rules The individual lines that define the
      # contract.
      def initialize(rules, mod)
        @rules = rules
        @mnod  = mod

        update_rule_values
      end

      private

      def update_rule_values
        names = rules.map(&:name).compact

        rules.each do |rule|
          rule.contract.gsub!(rule.name, "named_args[#{rule.name}]")
          rule.contract.gsub!('return', 'result')
        end
      end
    end
  end
end

