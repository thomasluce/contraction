module Contraction
  def self.extended(mod)
    instance = mod.allocate
    instance_methods = (mod.instance_methods - Object.instance_methods - Contracts.instance_methods)

    file_contents_by_filename = {}
    instance_methods.each do |method_name|
      file, line = instance.method(method_name).source_location
      filename = File.expand_path(file)
      file_contents = file_contents_by_filename[filename] || File.read(filename).split("\n")
      file_contents_by_filename ||= file_contents

      args    = []
      returns = [Object, '', 'true']
      file_contents[0..line-2].reverse.each do |line|
        line = line.strip
        next if line == ''
        break unless line.start_with?('#')
        break if line.start_with?('##')

        # if m = /^#\s*@return\s+(?<type>\[[^\]]+\])?\s*(?<message>[^{]+)?(\{(?<contract>[^}]+)\})?/.match(line)
        if m = /^#\s*@return\s+(\[[^\]]+\])?\s*([^{]+)?(\{([^}]+)\})?/.match(line)
          type = m[1].to_s.gsub(/(\[|\])/, '')
          type = type == '' ? Object : type.constantize
          contract = m[4].to_s.strip.gsub('return', "result")
          contract = contract == '' ? 'true' : contract
          returns = [type, m[2], contract]
        # elsif m = /^#\s*@param\s+(?<type>\[[^\]]+\])?\s*(?<name>[^\s]+)\s+(?<message>[^{]+)?(\{(?<contract>[^}]+)\})?/.match(line)
        elsif m = /^#\s*@param\s+(\[[^\]]+\])?\s*([^\s]+)\s+([^{]+)?(\{([^}]+)\})?/.match(line)
          type = m[1].to_s.gsub(/(\[|\])/, '')
          type = type == '' ? Object : type.constantize
          contract = m[5].to_s.strip.gsub(m[2], "named_args[#{m[2].inspect}]")
          contract = contract == '' ? 'true' : contract
          args << [type, m[2], m[3], contract]
        end
      end
      args.reverse!
      arg_names = args.map { |a| a[1] }
      arg_names.each do |name|
        returns[-1] = returns[-1].gsub(name, "named_args[#{name.inspect}]")
      end

      old_method = mod.instance_method(method_name)

      arg_checks = []
      result_check = nil
      mod.send(:define_method, method_name) do |*method_args|
        # FIXME: This needs to handle optional arguments as well
        raise ArgumentError.new("Wrong number of arguments (#{method_args.length} for #{args.length})") unless method_args.length == args.length
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
  end
end

