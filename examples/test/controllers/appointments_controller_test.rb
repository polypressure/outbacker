
#
# You'll probably want to move the following to your test_helper.rb
#
require 'outbacker'
require 'test_support/outbacker_stub'


class AppointmentsControllerTest < ActionController::TestCase


  test "user is redirected to the credits purchase page when they lack sufficient credits" do
    #
    # Stub the AppointmntsController#book_appointment method, specifying that
    # it will have an outcome of :insufficient_credits.
    #
    calendar_stub = Outbacker::OutbackerStub.new
    calendar_stub.stub('book_appointment', :insufficient_credits, stubbed_appointment)

    # This is a method we added to our controller to inject dependencies:
    @controller.inject_calendar(calendar_stub)

    post :create, appointment: {
      starts_at: '201506051600-600',
      ends_at: '201506051600-600',
      etc: 'and so on'
    }

    assert_redirected_to new_credits_url
  end


end
