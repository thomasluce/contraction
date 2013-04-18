Contraction
===========

A code-by-contract library for ruby, using RDoc documentation to enforce the contract requirements

Basic usage
===========

Just include Contraction at the bottom of your class/module:

```ruby

require 'rubygems'
require 'contraction'

class MySuperCoolClass
  ##
  # The foobar function takes a string and an integer between 1 and 100 and
  # joins them, returning the result.
  #
  # @param [String] foo A string to which we add the number
  # @param [Fixnum] bar A number to add to foo { bar >= 0 and bar <= 100 }
  # @return [String] The concatonation of foo and bar { return.start_with?(foo) and return.include?(bar.to_s) }
  def foobar(foo, bar)
    "#{foo} #{bar.to_s}"
  end

  include Contraction
end

```

And you're done.

You define your normal documentation (you do document your code, don't you?)
using regular RDoc syntax. For the params and returns, however, you can add an
extra bit of information at the end. Any code put in between curly braces
(`{}`) is evaluated as the contract for that param or return. You just use the
names of the params for their values, and `return` for the return value. If you
provide a type for either the param or the return, type-checking will be
enforced as well. A full-qualified type is recommended (`Foo::Bar` instead of `Bar`.)

Warning
=======

This will slow things down. All-in-all you're looking at about an 8x increase
in overhead vs just calling a function. It is not recommended that you use this
for every method in a deeply-nested code-path. This overhead is more-or-less
in-line with other Ruby design-by-contract libraries, however, and with the
added benefit of free documentation.

Also, this is not super-heavily tested. I've been using it myself and thought I
would release it to the world, but I don't do a lot of RDoc-fu, so YMMV.
Pull-requests welcome.
