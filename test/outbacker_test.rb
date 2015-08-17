require 'test_helper'

class OutbackerTest < Minitest::Test
  extend DefineTestNamesWithStrings

  def teardown
    Outbacker.configure do |c|
      c.blacklist = Outbacker::DEFAULT_BLACKLIST
      c.whitelist = Outbacker::DEFAULT_WHITELIST
    end
  end

  test "the right callbacks are invoked when callbacks are specified as methods" do
    outcomes = random_outcome_list
    input_values = input_list_that_results_in(outcomes)
    expected_blocks_called = expected_blocks_called_list_for(outcomes)
    actual_blocks_called = []

    input_values.each do |input_value|
      outbacked_domain_object.some_domain_method(input_value) do |on|
        on.outcome_of_outcome_1 do |callback_block_arg|
          actual_blocks_called << 'outcome 1'
        end

        on.outcome_of_outcome_2 do |callback_block_arg|
          actual_blocks_called << 'outcome 2'
        end

        on.outcome_of_outcome_3 do |callback_block_arg|
          actual_blocks_called << 'outcome 3'
        end
      end
    end

    assert_equal expected_blocks_called, actual_blocks_called
  end

  test "the right callbacks are invoked when callbacks are specified with symbols" do
    outcomes = random_outcome_list
    input_values = input_list_that_results_in(outcomes)
    expected_blocks_called = expected_blocks_called_list_for(outcomes)
    actual_blocks_called = []

    input_values.each do |input_value|
      outbacked_domain_object.some_domain_method(input_value) do |on_outcome|
        on_outcome.of(:outcome_1) do |callback_block_arg|
          actual_blocks_called << 'outcome 1'
        end

        on_outcome.of(:outcome_2) do |callback_block_arg|
          actual_blocks_called << 'outcome 2'
        end

        on_outcome.of(:outcome_3) do |callback_block_arg|
          actual_blocks_called << 'outcome 3'
        end
      end
    end

    assert_equal expected_blocks_called, actual_blocks_called
  end


  test "callback block arguments are passed in correctly" do
    actual_block_arguments_passed = []

    outbacked_domain_object.some_domain_method("input that will result in outcome 4") do |on|
      on.outcome_of_outcome_4 do |callback_block_arg1, callback_block_arg2, callback_block_arg3|
        actual_block_arguments_passed = [callback_block_arg1, callback_block_arg2, callback_block_arg3]
      end

      on.outcome_of_outcome_1 do |callback_block_arg|
        actual_block_arguments_passed << [callback_block_arg]
      end

      on.outcome_of_outcome_2 do |callback_block_arg|
        actual_block_arguments_passed << [callback_block_arg]
      end
    end

    assert_equal ["outcome 4 block arg1", "outcome 4 block arg2", "outcome 4 block arg3"], actual_block_arguments_passed
  end


  test "callback block arguments are passed in correctly when callbacks are specified with symbols" do
    actual_block_arguments_passed = []

    result = outbacked_domain_object.some_domain_method("input that will result in outcome 4") do |on_outcome|
      on_outcome.of(:outcome_4) do |callback_block_arg1, callback_block_arg2, callback_block_arg3|
        actual_block_arguments_passed = [callback_block_arg1, callback_block_arg2, callback_block_arg3]
      end

      on_outcome.of(:outcome_1) do |callback_block_arg|
        actual_block_arguments_passed << [callback_block_arg]
      end

      on_outcome.of(:outcome_2) do |callback_block_arg|
        actual_block_arguments_passed << [callback_block_arg]
      end
    end


    assert_equal ["outcome 4 block arg1", "outcome 4 block arg2", "outcome 4 block arg3"], actual_block_arguments_passed
  end


  test "exception raised when no callback is provided for the actual outcome" do
    assert_raises(RuntimeError) {
      outbacked_domain_object.some_domain_method("input that will result in outcome 4") do |on_outcome|
        on_outcome.of(:outcome_1) do |callback_block_arg|
        end

        on_outcome.of(:outcome_2) do |callback_block_arg|
        end
      end
    }
  end


  test "exception raised when the actual outcome is handled more than once" do
    assert_raises(RuntimeError) {
      outbacked_domain_object.some_domain_method("input that will result in outcome 4") do |on_outcome|
        on_outcome.of(:outcome_4) do |callback_block_arg|
        end

        on_outcome.of(:outcome_4) do |callback_block_arg|
        end
      end
    }
  end

  test "exception raised when no block is provided for a specific outcome and callbacks are specified with symbols" do
    assert_raises(RuntimeError) {
      outbacked_domain_object.some_domain_method("input that will result in outcome 1") do |on_outcome|
        on_outcome.of(:outcome_1)
      end
    }
  end

  test "exception raised when no block is provided for a specific outcome and callbacks are specified with methods" do
    assert_raises(RuntimeError) {
      outbacked_domain_object.some_domain_method("input that will result in outcome 1") do |on|
        on.outcome_of_outcome_1
      end
    }
  end

  test "exception raised when no outcome is triggered" do
    assert_raises(RuntimeError) {
      outbacked_domain_object.domain_method_with_no_outcome("input that will result in outcome 1") do |on_outcome|
        on_outcome.of(:outcome_1) do |callback_block_arg|
        end

        on_outcome.of(:outcome_2) do |callback_block_arg|
        end
      end
    }
  end

  test "exception raised when multiple outcomes are triggered" do
    assert_raises(RuntimeError) {
      outbacked_domain_object.domain_method_with_multiple_outcomes do |on_outcome|
        on_outcome.of(:outcome_1) do
        end

        on_outcome.of(:outcome_2) do
        end
      end
    }
  end

  test "when no callback block is provided it returns the callback key and any arguments that were to be passed to the callback" do
    domain_object = outbacked_domain_object
    outcomes = random_outcome_list
    input_values = input_list_that_results_in(outcomes)
    expected_return_values = outcomes.map { |outcome|
      [:"outcome_#{outcome}", "outcome #{outcome} block argument"]
    }
    actual_return_values = []

    input_values.each do |input_value|
      actual_return_values << domain_object.some_domain_method(input_value)
    end

    assert_equal expected_return_values, actual_return_values
  end

  test "can use 'and return' syntax following 'outcomes.handle...' in outbacked method" do
    outbacked_domain_object.domain_method_with_chained_return do |on_outcome|
      on_outcome.of(:outcome_1) do
        pass "Successfully handled outcome and chained return"
      end
    end
  end



  test "including within a subclass of ActiveRecord raises an exception" do
    assert_raises(RuntimeError) {
      class SomeActiveRecordClass < ActiveRecord::Base
        include Outbacker
      end
    }
  end


  test "including within a subclass of ActionController raises an exception" do
    assert_raises(RuntimeError) {
      class SomeControllerClass < ActionController::Base
        include Outbacker
      end
    }
  end


  test "including within a class that isn't a subclass of ActiveRecord does not raise an exception" do
    class SomeNonActiveRecordOrControllerClass
      include Outbacker
    end

    assert_respond_to SomeNonActiveRecordOrControllerClass.new, :with
  end

  test "trying to include a subclass of another blacklisted class raises an exception" do
    class BlacklistedClass
    end

    Outbacker.configure do |c|
      c.blacklist = [BlacklistedClass]
    end

    assert_raises(RuntimeError) {
      class MyBlacklistedClass < BlacklistedClass
        include Outbacker
      end
    }

  end

  test "when a whitelist is set, trying to include a subclass of a non-whitelisted class raises an exception" do
    class WhitelistedClass
    end

    class NonWhitelistedClass
    end

    Outbacker.configure do |c|
      c.whitelist = [WhitelistedClass]
    end

    assert_raises(RuntimeError) {
      class MyNonWhitelistedClass < NonWhitelistedClass
        include Outbacker
      end
    }

  end

  test "when a whitelist is set, trying to include a subclass of a whitelisted class doesn't raise an exception" do
    class WhitelistedClass
      include Outbacker
    end

    Outbacker.configure do |c|
      c.whitelist = [WhitelistedClass]
    end

    assert_respond_to WhitelistedClass.new, :with
  end



  private

  def random_outcome_list
    [*1..3].shuffle
  end

  def input_list_that_results_in(outcomes)
    outcomes.map { |outcome| "input that will result in outcome #{outcome}" }
  end

  def expected_blocks_called_list_for(outcomes)
    outcomes.map { |outcome| "outcome #{outcome}" }
  end

  def outbacked_domain_object
    SomeDomainObject.new
  end
end


class SomeDomainObject
  include Outbacker

  def some_domain_method(arg, &outcome_handlers)
    with(outcome_handlers) do |outcomes|
      case arg
      when 'input that will result in outcome 1'
        outcomes.handle :outcome_1, "outcome 1 block argument"
      when 'input that will result in outcome 2'
        outcomes.handle :outcome_2, "outcome 2 block argument"
      when 'input that will result in outcome 3'
        outcomes.handle :outcome_3, "outcome 3 block argument"
      when 'input that will result in outcome 4'
        outcomes.handle :outcome_4, "outcome 4 block arg1", "outcome 4 block arg2", "outcome 4 block arg3"
      end

    end
  end

  def domain_method_with_chained_return(&outcome_handlers)
    with(outcome_handlers) do |outcomes|
      outcomes.handle :outcome_1 and return
      fail "Should have returned"
    end
  end

  def domain_method_with_no_outcome(arg, &outcome_handlers)
    with(outcome_handlers) do |outcomes|
    end
  end

  def domain_method_with_multiple_outcomes(&outcome_handlers)
    with(outcome_handlers) do |outcomes|
      outcomes.handle :outcome_1
      outcomes.handle :outcome_2
    end
  end
end
