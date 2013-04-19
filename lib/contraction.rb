require 'string'
require 'contract'
module Contraction
  def self.patch_instance_method(mod, method_name)
    instance = mod.allocate
    args, returns = parse_comments(instance.method(method_name).source_location)

    arg_names = args.map(&:name)
    arg_names.each do |name|
      returns.contract = returns.contract.gsub(name, "named_args[#{name.inspect}]")
    end

    old_method = mod.instance_method(method_name)

    mod.send(:define_method, method_name) do |*method_args|
      named_args = args.each_with_index.inject({}) do |h, (arg, index)|
        h[arg.name] = method_args[index]
        h
      end

      args.each { |arg| arg.check!(named_args[arg.name], named_args) }
      result = old_method.bind(self).call(*method_args)
      returns.check!(result, named_args)

      result
    end
  end

  def self.patch_class_method(mod, method_name)
    args, returns = parse_comments(mod.method(method_name).source_location)
    arg_names = args.map(&:name)
    arg_names.each do |name|
      returns.contract = returns.contract.gsub(name, "named_args[#{name.inspect}]")
    end

    old_method = mod.method(method_name)

    arg_checks = []
    result_check = nil
    mod.define_singleton_method(method_name) do |*method_args|
      named_args = args.each_with_index.inject({}) do |h, (arg, index)|
        h[arg.name] = method_args[index]
        h
      end

      args.each { |arg| arg.check!(named_args[arg.name], named_args) }
      result = old_method.call(*method_args)
      returns.check!(result, named_args)

      result
    end
  end

  def self.file_content(filename)
    @file_contents ||= {}
    @file_contents[filename] ||= File.read(filename)
  end

  def self.parse_comments(location)
    file, line = location
    filename = File.expand_path(file)

    args    = []
    returns = Contraction::Contract.new()
    file_content(filename).split("\n")[0..line-2].reverse.each do |line|
      line = line.strip
      next if line == ''
      break unless line.start_with?('#')
      break if line.start_with?('##')

      if m = /^#\s*@return\s+(\[[^\]]+\])?\s*([^{]+)?(\{([^}]+)\})?/.match(line)
        type = m[1].to_s.gsub(/(\[|\])/, '')
        type = type == '' ? Object : type.constantize
        contract = m[4].to_s.strip.gsub('return', "result")
        contract = contract == '' ? 'true' : contract
        returns = Contraction::Contract.new(type: type, name: 'returns', message: m[2], contract: contract)
      elsif m = /^#\s*@param\s+(\[[^\]]+\])?\s*([^\s]+)\s+([^{]+)?(\{([^}]+)\})?/.match(line)
        type = m[1].to_s.gsub(/(\[|\])/, '')
        type = type == '' ? Object : type.constantize
        contract = m[5].to_s.strip.gsub(m[2], "named_args[#{m[2].inspect}]")
        contract = contract == '' ? 'true' : contract
        args << Contraction::Contract.new(type: type, name: m[2], message: m[3], contract: contract)
      end
    end
    args.reverse!
    return [args, returns]
  end

  def self.included(mod)
    instance_methods = (mod.instance_methods - Object.instance_methods - Contraction.instance_methods)

    instance_methods.each do |method_name|
      patch_instance_method(mod, method_name)
    end

    class_methods = (mod.methods - Object.methods - Contraction.methods)
    class_methods.each do |method_name|
      patch_class_method(mod, method_name)
    end
  end
end

