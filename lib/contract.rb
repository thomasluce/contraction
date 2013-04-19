module Contraction
  private

  class Contract
    attr_accessor :type, :name, :message, :contract
    def initialize(args={})
      @type = args[:type]
      @name = args[:name]
      @message = args[:message]
      @contract = args[:contract] || ''

      create_checkers!
    end

    def check!(value, named_args)
      @type_checker.call(value, named_args) if @type_checker
      if @contract_checker
        raise ArgumentError.new(contract_message(value)) unless @contract_checker.call(value, named_args)
      end
    end

    private

    def create_checkers!
      if type
        @type_checker = lambda { |value, named_args| raise ArgumentError.new(type_message(value)) unless value.is_a?(type) }
      end
      @contract_checker = eval("lambda { |result, named_args| #{contract} }") unless contract == ''
    end

    def type_message(value)
      "#{name} (#{value.inspect}) must be a #{type}"
    end

    def contract_message(value)
      "#{name} (#{message}) must fullfill #{contract.inspect}, but is #{value.inspect}"
    end
  end
end
