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

Ruby and the splendiferous always-open class
============================================

Because a class in Ruby can never really be "fully loaded", there are strange
cases where Contraction may not build contracts for all the methods that you
want it to. For example, if some third-party code modifies your class to add
methods at run-time, after Contraction has already been loaded. In this case,
if you would like contracts to be enabled for those classes, you can update the
annotated methods by calling:

```ruby
class MySuperCoolClass
  ...

  include Contraction
end

...

MySuperCoolClass.update_contracts
```

Please bear in mind that you will re-incur the overhead of parsing the RDoc
docs for each method.

Warning about speed/overhead
============================

This will slow things down. All-in-all you're looking at about an 8x increase
in overhead vs just calling a function. It is not recommended that you use this
for every method in a deeply-nested code-path. This overhead is more-or-less
in-line with other Ruby design-by-contract libraries, however, and with the
added benefit of free documentation. It is recommended that you have some
concept of environment (staging, dev, production, etc.), and only include
Contraction in development-like environments:

```ruby
require 'rubygems'
require 'contraction'

class MySuperCoolClass
  ...

  include Contraction if Rails.env.development?
end
```

