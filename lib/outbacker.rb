require "outbacker/version"
require "configurations"

module Outbacker

  include Configurations

  DEFAULT_BLACKLIST = [ActiveRecord::Base, ActionController::Base]
  DEFAULT_WHITELIST = []

  configuration_defaults do |c|
    c.blacklist = DEFAULT_BLACKLIST
    c.whitelist = DEFAULT_WHITELIST
  end


  #
  # DSL-ish factory method to create an instance of OutcomeHandlerSet
  # given a block of outcome handlers.
  #
  # To be used within your business-logic methods in combination with
  # the OutcomeHandlerSet#handle method.
  #
  def with(outcome_handlers)
    outcome_handler_set = OutcomeHandlerSet.new(outcome_handlers)
    yield outcome_handler_set

    if outcome_handlers.nil?
      return outcome_handler_set.triggered_outcome, *outcome_handler_set.args
    else
      raise "No outcome selected" unless outcome_handler_set.outcome_handled?
    end
  end

  #
  # Class to encapsulate the processing of a block of outcome handlers.
  #
  OutcomeHandlerSet = Struct.new(:outcome_handlers,
                                 :triggered_outcome,
                                 :args,
                                 :handled_outcome) do

    #
    # Process the outcome specified by the given outcome_key,
    # using the outcome handlers set on this OutcomeHandlerSet
    # instance. Any additiona arbitrary arguments can be passed
    # through to the corresponding outcome handler callback.
    #
    def handle(outcome_key, *args)
      self.triggered_outcome = outcome_key
      self.args = args

      if outcome_handlers
        outcome_handlers.call(self)
        raise "No outcome handler for outcome #{outcome_key}" unless outcome_handled?
      end
      true
    end

    #
    # Internal method to indicate that the outcome has been
    # handled by some han dler.
    #
    def outcome_handled?
      !!self.handled_outcome
    end

    #
    # Specify an outcome handler callback block for the specified
    # outcome key.
    #
    def of(outcome_key, &outcome_block)
      execute_outcome_block(outcome_key, &outcome_block)
    end

    #
    # Provides an alternate way to specify a callback block using
    # method names.
    #
    def method_missing(method_name, *args, &outcome_block)
      super unless /^outcome_of_(?<suffix>.*)/ =~ method_name.to_s
      outcome_key = suffix.to_sym

      execute_outcome_block(outcome_key, &outcome_block)
    end


    private

    #
    # Internal helper method to execute the given outcome block
    # if it matches the triggered outcome.
    #
    def execute_outcome_block(outcome_key, &outcome_block)
      if !outcome_block
        raise "No block provided for outcome #{outcome_key}"
      end

      if outcome_key == self.triggered_outcome
        raise "Outcome #{outcome_key} already handled" if outcome_handled?
        self.handled_outcome = outcome_key
        outcome_block.call(*self.args)
      end
    end

  end

  #
  # Restrict where Outbacker can be included.
  #
  def self.included(target_module)
    apply_whitelist(target_module) if Outbacker.configuration.whitelist.any?
    apply_blacklist(target_module) if Outbacker.configuration.blacklist.any?
  end

  def self.apply_whitelist(target_module)
    Outbacker.configuration.whitelist.each do |whitelisted_classs|
      return if target_module.ancestors.include?(whitelisted_classs)
    end
    fail "Can only include #{self.name} within a subclass of: #{Outbacker.configuration.whitelist.join(', ')}"
  end

  def self.apply_blacklist(target_module)
    Outbacker.configuration.blacklist.each do |blacklisted_class|
      if target_module.ancestors.include?(blacklisted_class)
        fail "Cannot include #{self.name} within an #{blacklisted_class} class, a plain-old Ruby object is preferred."
      end
    end
  end

end
