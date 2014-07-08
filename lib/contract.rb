module Contraction
  class Contract
    attr_reader :rules, :mod, :method_name, :params

    # @params [Array<TypedLine>] rules The individual lines that define the
    # contract.
    def initialize(rules, mod, method_name)
      @rules       = rules
      @mod         = mod
      @method_name = method_name

      update_rule_values
      get_method_definition
    end

    # Test weather the arguments to a method are of the correct type, and meet
    # the correct contractual obligations.
    def valid_args?(*method_args)
      return true if @rules.nil?
      named_args = params.each_with_index.inject({}) do |h, (param, index)|
        h[param.to_s] = method_args[index]
      h
      end

      b = binding
      param_rules.all? do |rule|
        raise ArgumentError.new("#{rule.name} (#{named_args[rule.name].inspect}) must be a #{rule.type}") unless rule.valid?(named_args[rule.name])
        rule.evaluate_in_context(b, method_name, named_args[rule.name])
      end
    end

    # Tests weather or not the return value is of the correct type and meets
    # the correct contractual obligations.
    def valid_return?(*method_args, result)
      named_args = params.each_with_index.inject({}) do |h, (param, index)|
        h[param] = method_args[index]
      h
      end

      return true unless return_rule
      unless return_rule.valid?(result)
        raise ArgumentError.new("Return value of #{method_name} must be a #{return_rule.type}")
      end
      if return_rule.contract
        b = binding
        return_rule.evaluate_in_context(b, method_name, result)
      end
    end

    private

    def return_rule
      @return_rule ||= @rules.select { |r| r.is_a?(Contraction::Parser::ReturnLine) }.first
    end

    def param_rules
      @param_rules ||= @rules.select { |r| r.is_a?(Contraction::Parser::ParamLine) }
    end

    def get_method_definition
      @params = mod.instance_method(method_name).parameters.map { |p| p.last }
    end

    def update_rule_values
      names = rules.map(&:name).compact.uniq

      rules.each do |rule|
        names.each do |name|
          rule.contract.gsub!(name, "named_args['#{name}']")
        end
        rule.contract.gsub!('return', 'result')
      end
    end
  end
end

