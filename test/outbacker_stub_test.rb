require 'test_helper'

class OutbackerStubTest < Minitest::Test
  extend DefineTestNamesWithStrings

  test "#stub defines the specified method on the stub instance" do
    outbacker_stub = Outbacker::OutbackerStub.new

    outbacker_stub.stub('register_user', :successful_registration, Object.new)

    assert_respond_to outbacker_stub, 'register_user'
  end

  test "#stub invokes the outcome callback for the specified outcome key" do
    outbacker_stub = Outbacker::OutbackerStub.new
    correct_block_executed = false

    outbacker_stub.stub('register_user', :successful_registration, Object.new)

    outbacker_stub.register_user do |on_outcome|
      on_outcome.of(:successful_registration) do |user|
        correct_block_executed = true
      end

      on_outcome.of(:failed_validation) do |user|
        correct_block_executed = false
      end

      on_outcome.of(:some_other_outcome) do |user|
        correct_block_executed = false
      end
    end

    assert correct_block_executed, "Outcome block not executed by stub."
  end

  test "#stub passes the specified block arguments to the outcome block" do
    outbacker_stub = Outbacker::OutbackerStub.new
    block_arg_1 = Object.new
    block_arg_2 = Object.new
    block_args_passed = []

    outbacker_stub.stub('register_user', :successful_registration, block_arg_1, block_arg_2)

    outbacker_stub.register_user do |on_outcome|
      on_outcome.of(:successful_registration) do |arg1, arg2|
        block_args_passed = [arg1, arg2]
      end
    end

    assert_equal [block_arg_1, block_arg_2], block_args_passed
  end


  test "#new defines the specified method on the stub instance" do
    outbacker_stub = Outbacker::OutbackerStub.new('register_user', :successful_registration, Object.new)

    assert_respond_to outbacker_stub, 'register_user'
  end

  test "#new invokes the outcome callback for the specified outcome key" do
    outbacker_stub = Outbacker::OutbackerStub.new('register_user', :successful_registration, Object.new)
    correct_block_executed = false

    outbacker_stub.register_user do |on_outcome|
      on_outcome.of(:successful_registration) do |user|
        correct_block_executed = true
      end

      on_outcome.of(:failed_validation) do |user|
        correct_block_executed = false
      end

      on_outcome.of(:some_other_outcome) do |user|
        correct_block_executed = false
      end
    end

    assert correct_block_executed, "Outcome block not executed by stub."
  end

  test "#new passes the specified block arguments to the outcome block" do
    block_arg_1 = Object.new
    block_arg_2 = Object.new
    outbacker_stub = Outbacker::OutbackerStub.new('register_user', :successful_registration, block_arg_1, block_arg_2)
    block_args_passed = []

    outbacker_stub.register_user do |on_outcome|
      on_outcome.of(:successful_registration) do |arg1, arg2|
        block_args_passed = [arg1, arg2]
      end
    end

    assert_equal [block_arg_1, block_arg_2], block_args_passed
  end

end
