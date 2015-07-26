require 'coveralls'
Coveralls.wear!

require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end



require 'minitest/autorun'
require 'minitest/pride'

#
# Stub out ActiveRecord just for testing purposes, so we don't
# need to load and have a dependency on Rails just to test that
# the module shouldn't be included directly within an
# ActiveRecord class.
#
module ActiveRecord
  class Base
  end
end

module ActionController
  class Base
  end
end

require 'outbacker'
require 'test_support/outbacker_stub'


#
# Allow for Rails-style test names, where test names can be defined with
# strings rather than a Ruby-method name with underscores.
#
# Usage:
#
#   class
#     extend DefineTestNamesWithStrings
#     ...
#     test "a descriptive test name" do
#       ...
#     end
#   end
#
# Note: We could have just pulled this in from ActiveSupport::TestCase,
# but I wanted to avoid the dependency.
#
module DefineTestNamesWithStrings

  # Helper to define a test method using a String. Under the hood, it replaces
  # spaces with underscores and defines the test method.
  #
  #   test "verify something" do
  #     ...
  #   end
  def test(name, &block)
    test_name = "test_#{name.gsub(/\s+|,/,'_')}".to_sym
    defined = method_defined? test_name
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end
