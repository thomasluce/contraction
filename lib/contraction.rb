require 'string'
require 'parser'

module Contraction
  # Call this method to update contracts for any methods that may have been
  # added after the class/module file was loaded by some third-party code. It's
  # unlikely that you will need this method, but I thought I would include it
  # just in case.
  # @param [Class] mod The module or class to update contracts for.
  def self.update_contracts(mod)
    instance = mod.allocate
    instance_methods = (mod.instance_methods - Object.instance_methods - Contraction.instance_methods)

    # FIXME: Deal with weather it is an instance or class method a bit nicer.
    instance_methods.each do |method_name|
      file_contents, line_no = read_file_for_method(instance, method_name)

      contract = Contraction::Parser.parse(file_contents[0..line_no-2].reverse, mod, method_name)
      define_wrapped_method(mod, method_name, contract)
    end
  end

  # Called by ruby when Contraction is included in a class.
  def self.included(mod)
    update_contracts(mod)
  end

  def self.instance_methods_for(klass)
    klass.public_instance_methods - Object.public_instance_methods - Module.public_instance_methods
  end

  def self.class_methods_for(klass)
    klass.public_methods - Object.public_methods - Module.public_methods
  end

  def self.methods_for(klass)
    { class: class_methods_for(klass), instance: instance_methods_for(klass) }
  end

  private

  def self.read_file_for_method(instance, method_name)
    file, line = instance.method(method_name).source_location
    filename = File.expand_path(file)
    file_contents = File.read(filename).split("\n")
    return [file_contents, line]
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
end

