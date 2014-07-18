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

