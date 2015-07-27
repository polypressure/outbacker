#
# Conventional Rails controller, with the create method
# implemented twice: before and after using Outbacker.
#
class AppointmentsController < ApplicationController

  #
  # A conventional controller method, before using Outbacker:
  #
  def create
    @appointment = Appointment.new(appointment_params)
    if @appointment.save
      redirect_to appointments_path,
                  notice: "Your appointment has been booked."
    else
      render :new
    end
  rescue InsufficientCredits => e
    redirect_to new_credits_path,
                alert: "You don't have enough credits, please purchase more."
  end

  #
  # The same controller method with Outbacker:
  #
  def create
    #
    # We've replaced the call to Appointment#save with a method defined
    # on a separate plain-old Ruby object (app/domain/appointment_calendar.rb)
    # that reifies the business concept of booking an appointment.
    #
    # We pass a block to this method which declaratiely specifies
    # how we want to to respond to each of the possible outcomes
    # from the book_appointment method.
    #
    calendar.book_appointment(appointment_params) do |on_outcome|

      on_outcome.of(:successful_booking) do |appointment|
        redirect_to appointments_path,
                    notice: 'Your appointment has been booked.'
      end

      on_outcome.of(:insufficient_credits)
        redirect_to new_credits_path,
                    alert: "You don't have enough credits, please purchase more."
      end

      on_outcome.of(:failed_validation) do |appointment|
        @appointment = appointment
        render :new
      end

    end
  end

  #
  # This lets us inject a stubbed calendar to support testing:
  #
  def inject_calendar(appointment_calendar)
    @calendar = appointment_calendar
  end

  private

  #
  # Instantiate your business-logic object as suits your project:
  #
  def calendar
    @calendar ||= AppointmentCalendar.for_the current_user
  end



end
