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

    methods_for(mod).each do |(type, methods)|
      methods.each do |method_name|
        file_contents, line_no = read_file_for_method(instance, method_name, type)

        contract = Contraction::Parser.parse(file_contents[0..line_no-2].reverse, mod, method_name, type)
        define_wrapped_method(mod, method_name, contract, type)
      end
    end
  end

  # Called by ruby when Contraction is included in a class.
  def self.included(mod)
    update_contracts(mod)
  end

  # Get all the public instance methods for a given class, that are unique to
  # class (ie, not built-ins)
  # @param [Class] klass The class to get the methods from
  # @return [Array<Symbol>] The method names
  def self.instance_methods_for(klass)
    klass.public_instance_methods - Object.public_instance_methods - Module.public_instance_methods
  end

  # Get all the public class methods for a given class that are unique to the
  # class (ie, not built-ins). NOTE: doing something like the following _doesn't_
  # make a class method private:
  # class Foo
  #     private
  #     def self.foobar
  #     end
  # end
  #
  # That's because defining a method on an object, even `self`, re-opens the
  # object to define the method on it. It's the same as saying `def
  # some_object.foobar`, only in this case `some_object` is the handy-dandy
  # `self`. To make that really private, you can do:
  # class Foo
  #     private
  #     def self.foobar
  #     end
  #     private_class_method :foobar
  # end
  #
  # ... or ...
  # class Foo
  #     private
  #     class << self
  #         def self.foobar
  #         end
  #     end
  # end
  # @param [Class] klass The class to get the methods from
  # @return [Array<Symbol>] The method names
  def self.class_methods_for(klass)
    klass.public_methods - Object.public_methods - Module.public_methods
  end

  def self.methods_for(klass)
    { class: class_methods_for(klass), instance: instance_methods_for(klass) }
  end

  private

  def self.read_file_for_method(instance, method_name, type)
    file, line = nil, nil
    if type == :class
      file, line = instance.class.method(method_name).source_location
    elsif type == :instance
      file, line = instance.method(method_name).source_location
    else
      raise ArgumentError.new("Unknown method type, #{type.inspect}")
    end
    filename = File.expand_path(file)
    file_contents = File.read(filename).split("\n")
    return [file_contents, line]
  end

  def self.define_wrapped_method(mod, method_name, contract, type)
    old_method = type == :instance ? mod.instance_method(method_name) : mod.method(method_name)

    arg_checks = []
    result_check = nil
    type = type == :class ? :define_singleton_method : :define_method
    mod.send(type, method_name) do |*method_args|
      contract.valid_args?(*method_args)
      result = nil
      if old_method.respond_to?(:bind)
        result = old_method.bind(self).call(*method_args)
      else
        result = old_method.call(*method_args)
      end
      contract.valid_return?(*method_args, result)
      result
    end
  end
end

