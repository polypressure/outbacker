#
# Plain-old Ruby object that contains our business logic.
#
# Can be a domain object, a service object, a use-case object,
# a DCI context, or whatever.
#
class AppointmentCalendar

  #
  # Include the Outbacker module. See config/initializers/outbacker.rb
  # for the restrictions on where you can include this.
  #
  include Outbacker

  #
  # An "outbacked" domain method, i.e., one that can
  # process outcome callbacks passed into it—here via
  # the &outcome_handlers parameter:
  #
  def book_appointment(params, &outcome_handlers)

    #
    # Immediately pass the outcome_handlers block to the
    # with method (provided by Outbacker), which in turn
    # takes a block that must wrap the body of your
    # business-logic method:
    #
    with(outcome_handlers) do |outcomes|
      if user_lacks_sufficient_credits?
        #
        # Trigger the insufficient_credits outcome and run the
        # corresponding callback block (provided via the
        # &outcome_handlers block):
        #
        outcomes.handle :insufficient_credits
        return
      end

      appointment = Appointment.new(params)
      if appointment.save
        ledger.deduct_credits_for appointment

        notify_user_about appointment
        notify_office_about appointment

        #
        # Trigger the successful_booking outcome and run the
        # corresponding callback block (provided via the
        # &outcome_handlers block), and pass that block
        # the newly-booked appointment:
        #
        outcomes.handle :successful_booking, appointment
      else
        #
        # Trigger the failed_validation outcome and run the
        # corresponding callback block (provided via the
        # &outcome_handlers block), and pass that block
        # the appointment that failed validation:
        #
        outcomes.handle :failed_validation, appointment
      end
    end
  end

  #
  # Any other public business logic methods.
  # ...
  #


  private

  def user_lacks_sufficient_credits?
    # Check current user's credit balance is >= cost of appointment.
  end

  def ledger
    # Return Ledger object that manages credit balances and transactions.
  end

  def notify_user_about(appointment)
    # Enqueue background jobs to send emails, SMS, phone push notifications, etc.
    # This lets us avoids ActiveRecord callback spaghetti.
  end

  def notify_office_about(appointment)
    # Post office dashboard notification and activity feed entry, enqueue
    # background jobs to send emails, SMS, phone push notifications, etc.
    # This also lets us avoids ActiveRecord callback spaghetti.
  end

  #
  # Any other private internal helper methods.
  #
end
