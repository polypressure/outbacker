#
# Provides a simple means to stub "Outbacked" methods. Specifically,
# it lets you specify what outcome callback you want invoked on
# your stubbed method.
#
# Usage:
# stubbed_object = OutbackerStub.new
# stubbed_object.stub('stubbed_method_name',
#                     :desired_outcome,
#                     block_arg1, block_arg2, ...)
#
# Alternatively, combine instantiation and stubbing:
# stubbed_object = OutbackerStub.new('stubbed_method_name',
#                                    :desired_outcome,
#                                    block_arg1, block_arg2, ...)
#
# Note that this only provides stubbing functionality, no mocking
# functionality (i.e., ability to verify that a method was invoked on
# a test double) is provided. This should be sufficient for your test
# needs, as you can/should write separate tests to verify that
# the expected methods were invoked on your double.
#
module Outbacker
  class OutbackerStub
    include Outbacker

    def initialize(method_name=nil, outcome_key=nil, *block_args)
      if method_name && outcome_key
        stub_outbacked_method(method_name, outcome_key, *block_args)
      end
    end

    def stub_outbacked_method(method_name, outcome_key, *block_args)
      define_singleton_method(method_name, ->(*args, &outcome_handlers) {
        with(outcome_handlers) do |outcomes|
          outcomes.handle outcome_key, *block_args
        end
      })
    end

    def stub_simple_method(method_name, result)
      define_singleton_method(method_name) do
        result
      end
    end

  end
end
