require 'string'
require 'parser'

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

  def self.define_wrapped_method(mod, method_name, contract)
    old_method = mod.instance_method(method_name)

    arg_checks = []
    result_check = nil
    mod.send(:define_method, method_name) do |*method_args|
      contract.valid_args?(*method_args)
      result = old_method.bind(self).call(*method_args)
      contract.valid_return?(*method_args, result)
      result
    end
  end

  public

  def self.update_contracts(mod)
    instance = mod.allocate
    instance_methods = (mod.instance_methods - Object.instance_methods - Contraction.instance_methods)

    instance_methods.each do |method_name|
      file_contents, line_no = read_file_for_method(instance, method_name)

      contract = Contraction::Parser.parse(file_contents[0..line_no-2].reverse, mod, method_name)
      define_wrapped_method(mod, method_name, contract)
    end
  end

  def self.included(mod)
    update_contracts(mod)
  end
end

