require 'string'
module Contraction
  private

  RETURN_LINE_REGEX = /^#\s*@return\s+(?<type>\[[^\]]+\])?\s*(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/
  PARAM_LINE_REGEX  = /^#\s*@param\s+(?<type>\[[^\]]+\])?\s*(?<name>[^\s]+)\s+(?<message>[^{]+)?(?<contract>\{([^}]+)\})?/

  def self.read_file_for_method(instance, method_name)
    file, line = instance.method(method_name).source_location
    filename = File.expand_path(file)
    file_contents = File.read(filename).split("\n")
    return [file_contents, line]
  end

  def self.extract_params_and_return(lines)
    args = []
    returns = [Object, '', 'true']
    lines.each do |line|
      line = line.strip
      next if line == ''
      break unless line.start_with?('#')
      break if line.start_with?('##')

      if m = RETURN_LINE_REGEX.match(line)
        type = m['type'].to_s.gsub(/(\[|\])/, '')
        type = type == '' ? Object : type.constantize
        contract = m['contract'].to_s.strip.gsub('return', "result")
        contract = contract == '' ? 'true' : contract
        contract = contract.gsub(/(^\{)|(\}$)/, '')
        returns = [type, m['message'], contract]
      elsif m = PARAM_LINE_REGEX.match(line)
        type = m['type'].to_s.gsub(/(\[|\])/, '')
        type = type == '' ? Object : type.constantize
        contract = m['contract'].to_s.strip.gsub(m['name'], "named_args[#{m['name'].inspect}]")
        contract = contract == '' ? 'true' : contract
        contract = contract.gsub(/(^\{)|(\}$)/, '')
        args << [type, m['name'], m['message'], contract]
      end
    end

    return [args.reverse, returns]
  end

  def self.define_wrapped_method(mod, method_name, args, returns)
    arg_names = args.map { |a| a[1] }
    arg_names.each do |name|
      returns[-1] = returns[-1].gsub(name, "named_args[#{name.inspect}]")
    end

    old_method = mod.instance_method(method_name)

    arg_checks = []
    result_check = nil
    mod.send(:define_method, method_name) do |*method_args|
      named_args = args.each_with_index.inject({}) do |h, (arg, index)|
        type, name, message, contract = arg
        h[name] = method_args[index]
        h
      end

      b = binding
      if arg_checks.empty?
        arg_checks = args.map do |arg|
          type, name, message, contract = arg
          value = named_args[name]
          checker = nil
          lambda { |named_args|
            raise ArgumentError.new("#{name} (#{value.inspect}) must be a #{type}") unless value.is_a?(type)
            checker = eval("lambda { |named_args| #{contract} }", b) if checker.nil?
            unless checker.call(named_args)
              raise ArgumentError.new("#{name} (#{message}) must fullfill #{contract.inspect}, but is #{value.inspect}")
            end
          }
        end
      end
      arg_checks.each { |c| c.call(named_args) }

      result = old_method.bind(self).call(*method_args)

      if result_check.nil?
        checker = nil
        result_check = lambda { |named_args|
          type, message, contract = returns
          raise ArgumentError.new("Return value of #{method_name} must be a #{type}") unless result.is_a?(type)
          checker = eval("lambda { |named_args| #{contract} }", b) if checker.nil?
          unless checker.call(named_args)
            raise ArgumentError.new("Return value of #{method_name} (#{message}) must fullfill #{contract.inspect}, but is #{result.inspect}")
          end
        }
      end
      result_check.call(named_args)

      result
    end
  end

  public

  def self.included(mod)
    instance = mod.allocate
    instance_methods = (mod.instance_methods - Object.instance_methods - Contraction.instance_methods)

    instance_methods.each do |method_name|
      file_contents, line_no = read_file_for_method(instance, method_name)

      args, returns = extract_params_and_return(file_contents[0..line_no-2].reverse)
      define_wrapped_method(mod, method_name, args, returns)
    end
  end
end

