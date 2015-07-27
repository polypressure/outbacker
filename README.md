# Outbacker

[![Build Status](https://travis-ci.org/polypressure/outbacker.svg?branch=master)](https://travis-ci.org/polypressure/outbacker)
[![Code Climate](https://codeclimate.com/github/polypressure/outbacker/badges/gpa.svg)](https://codeclimate.com/github/polypressure/outbacker)
[![Test Coverage](https://codeclimate.com/github/polypressure/outbacker/badges/coverage.svg)](https://codeclimate.com/github/polypressure/outbacker/coverage)

Rails developers have long known how important it is to keep controllers "skinny" and free of business logic. Controllers are supposed to be dumb dispatchers that take results from the model layer and turn them into redirects, flash messages, form re-renderings, session state updates, JSON responses, HTTP status codes, and so on.

But the conditional logic in typical Rails controllers to act on results from model methods and decide what to do next far too often attracts business logic and spirals out of control. Complicated logic sneaks into our controllers as we add code to handle new features, stories, and special cases. And the cultural and process controls we put in place to enforce good code hygiene chronically break down in the face of schedule pressure, growing teams, emergency fixes, etc.

**Outbacker** ("outcome callbacks") is a very simple micro library that makes it easy to keep controllers free of this conditional logic. Controllers become simple, declarative mappings of business logic results to the redirects, flash messages, session state updates, HTTP status codes, and other actions that deliver results to the user.

It turns out that not only is Outbacker a prophylaxis against fat, complicated controllers, it more generally supports a very simple, low-ceremony way to write intention-revealing Rails code with both skinny controllers _and_ skinny models. If you feel these are worthwhile aims for your Ruby/Rails code—but you've found many approaches to accomplish this ineffective or not worth the trouble—then you might find Outbacker valuable.

**Note:** The README that follows has a lot of motivation, rationale, and explanation—arguably excessively so for such a simple library. If you're too impatient  , you can go straight to some [code examples](https://github.com/polypressure/outbacker/tree/master/examples). Hopefully, these examples are sufficient for you to get an understanding of what Outbacker provides, and how to use it. If not, you can always come back to this readme.

## A Typical Rails Controller

Let's look at a typical simple Rails controller method:

```ruby
class AppointmentsController < ApplicationController

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

  ...

end
```

For the most part, this is idiomatic Rails controller code, and it's free of business logic. We can guess that this method is trying to book an appointment of some sort, with a prerequisite that the user has a minimum account balance denominated in something called "credits." But we're having to make assumptions about the intent of the code, because it's trying to express business logic with the limited, non-intention-revealing vocabulary of low-level ActiveRecord CRUD verbs.

ActiveRecord's constrained interface also forces us to fit our outcomes into one of only two values: true or false, representing a successful save or a validation error respectively. Unfortunately, an outcome where the user lacks sufficient credits can't be naturally expressed as a validation error here. That's because we don't want the controller to merely re-render the form—as we do with typical validation errors. We want to redirect the user to some other page where they can purchase additional credits.

Consequently, this code is resorting to the use of an exception to indicate that the user doesn't have enough credits to book an appointment. But exceptions should be reserved for unexpected or abnormal conditions that the code isn't prepared to handle.

Alternatively, we could set some sort of flag or status code on the Appointment model. But checking return values and status codes results in some ugly conditional code in our controller. And as we've said, too often this conditional code spirals out of control, is a magnet for business logic, and becomes increasingly brittle over time.

## Improving Rails Controllers with Outbacker

Here's how the same controller looks with Outbacker:

```ruby
class AppointmentsController < ApplicationController

  def create
    calendar.book_appointment(appointment_params) do |on_outcome|

      on_outcome.of(:successful_booking) do |appointment|
        redirect_to appointments_path,
                    notice: 'Your appointment has been booked.'
      end

      on_outcome.of(:insufficient_credits) do
        redirect_to new_credits_path,
                    alert: "You don't have enough credits, please purchase more."
      end

      on_outcome.of(:failed_validation) do |appointment|
        @appointment = appointment
        render :new
      end

    end
  end

  private

  def calendar
    @calendar ||= AppointmentCalendar.for_the current_user
  end

  ...

end
```

Hopefully, the above example is mostly self-explanatory, but here are a few notes:

First, we've replaced the ActiveRecord `save` method with a `book_appointment` method defined on a separate plain-old Ruby `AppointmentCalendar` object (which we'll discuss in more detail shortly). This reifies the business task of booking an appointment, giving us a method that unambiguously conveys intent.

This also allows us to replace the conditional logic that's required in Rails controllers to act on results. Instead, we now declaratively specify the actions we'd like to execute for each possible outcome from invoking `AppointmentCalendar#book_appointment`. This is done with a DSL-ish block passed to our business logic method (`book_appointment`), which provides short callback blocks for each of the possible outcomes when trying to book an appointment:

* :successful_booking
* :insufficient_credits
* :failed_validation

The `on_outcome` object in the above controller is an instance of an internal class used by Outbacker (`Outbacker::OutcomeHandlerSet`). We've named it "on_outcome" strictly for the sake of readability, and to indulge the DSL-ish syntax. For the most part, you really don't need to worry about the details of this object. You simply invoke the `of` method on it to define an outcome callback block, providing a key corresponding to the specific outcome this block handles—in this case, `successful_booking`. As we'll see shortly, this key matches a corresponding key used in our business logic method, `AppointmentCalendar#book_appointment`.

(FYI, these "outcome callbacks" are the namesake for this library, "Outbacker." Yeah, I know, pretty weak and uninspired. But you know how they say naming is hard.)

An outcome callback block can take any number of arguments, passed on from the business-logic method. Here, a single Appointment object representing the appointment that has been booked is passed to the outcome callback block for `:successful_booking`. And a single Appointment object with validation errors is passed to the outcome callback block for `:failed_validation`.

You can see that our controller method can now easily accommodate any number of possible outcomes from our business logic, without having to pile on more conditional checks and clauses, exception rescue blocks, etc. There's no reason for our controller to be anything but skinny.

Another benefit is that all the cases and outcomes that we need to consider from your business logic method are explicitly enumerated—as opposed to having to be inferred from the various conditional paths in a typical Rails controller method. This makes it easier to come in and quickly understand the intent of the code, makes for easier testing, etc.

### Alternate, method-based syntax

Outbacker provides an alternative syntax here that uses dynamic method names against the yielded object, rather than passing a symbol to the `of` method:

```ruby
class AppointmentsController < ApplicationController

  def create

    calendar.book_appointment(appointment_params) do |on|

      on.outcome_of_successful_booking do |appointment|
        redirect_to appointments_path,
                    notice: 'Your appointment has been booked.'
      end

      on.outcome_of_insufficient_credits do
        redirect_to new_credits_path,
                    alert: "You don't have enough credits, please purchase more."
      end

      on.outcome_of_failed_validation do |appointment|
        @appointment = appointment
        render :new
      end

    end

  end


  private

  def calendar
    @calendar ||= AppointmentCalendar.for_the current_user
  end

  ...

end
```

Note that your method names here must begin with the "outcome_of" prefix. The outcome key is extracted from the method name by stripping that prefix. The `on_outcome` object has been renamed to simply `on`, again for the sake of readability.

For whatever reasons, you might prefer this syntax. But note that the implementation of this syntax depends on `method_missing`—which as has been discussed elsewhere, can be problematic.


## Business Logic Objects with Outbacker

Now, let's take a look at the corresponding business logic object that uses Outbacker:

```ruby
class AppointmentCalendar

  # Needed to make this an "outbacked" object.
  include Outbacker

  #
  # An "outbacked" domain method, i.e., one that can
  # process outcome callbacks passed into it—here via
  # the &outcome_handlers parameter:
  #
  def book_appointment(params, &outcome_handlers)
    with(outcome_handlers) do |outcomes|
      if user_lacks_sufficient_credits?
        outcomes.handle :insufficient_credits
        return
      end

      appointment = Appointment.new(params)
      if appointment.save
        ledger.deduct_credits_for appointment

        notify_user_about appointment
        notify_office_about appointment

        outcomes.handle :successful_booking, appointment
      else
        outcomes.handle :failed_validation, appointment
      end
    end
  end

  ...

  private

  def user_lacks_sufficient_credits?
    # Check current user's credit balance is >= cost of appointment.
  end

  def ledger
    # Return Ledger object that manages credit balances and transactions.
  end

  def notify_user_about(appointment)
    # Enqueue background jobs to send emails, SMS, phone push notifications, etc.
  end

  def notify_office_about(appointment)
    # Post office dashboard notification and activity feed entry, enqueue
    # background jobs to send emails, SMS, phone push notifications, etc.
  end

  ...

end
```

### Including the Outbacker module

The first thing to point out here: our business-logic object is a PORO, i.e., a plain-old Ruby object. It can pretty much be whatever type of PORO you want: a domain object, a use case object, a DCI context, a service object—whatever.

Next, to enable Outbacker support in your business object, you have to `include` the `Outbacker` module in your class. For the most part, you can include Outbacker in any class, but to discourage you from putting business logic in your ActiveRecord models, by default Outbacker will actually raise an exception if you try to include it within an ActiveRecord (or ActiveController) subclass. This is Outbacker's simple tactic for encouraging us to keep our models skinny. The bulk of our business logic goes into easily-tested POROs, while our models are focused on persistence and simple validation rules—and free of things like ActiveRecord callback spaghetti.

#### Excluding/allowing other types of business objects

You can actually configure the policy regarding where Outbacker can be included. First, you can customize the blacklisted superclasses. Create a `config/initializers/outbacker.rb` file like this:

```ruby
Outbacker.configure do |c|
  c.blacklist = [ActiveRecord::Base, ActionController::Base, MyBlacklistedClass]
end
```

This says that you cannot include Outbacker in any subclass of `ActiveRecord`, `ActionController`, or `MyBlacklistedClass`. If anybody on your team tries to include Outbacker within a subclass of any of these classes, an exception will be raised.

Alternatively, you can specify a whitelist:

```ruby
Outbacker.configure do |c|
  c.whitelist = [UseCase, ServiceObject, DomainObject]
end
```

This says that you can only include Outbacker within subclasses of `UseCase`, `ServiceObject`, or `DomainObject`. If anybody on your team tries to include Outbacker within a subclass of any other class, an exception will be raised. This is the recommended way for configuring your policy.

### Defining your "Outbacked" business logic method

Your business-logic method that uses Outbacker (or more conveniently, an "Outbacked" method) can of course take any number of arguments, as long as its last argument is a block—which as we've seen is where the outcome callbacks are provided. By convention, we name the argument for this block `outcome_handlers`. We immediately pass it to the `Outbacker::with(outcome_handlers)` method, which must wrap the entire body of your Outbacked method:

```ruby
def book_appointment(params, &outcome_handlers)
  with(outcome_handlers) do |outcomes|
    # Business logic here.
  end
end
```

Within our business logic methods, when we know what the outcome is, we trigger the corresponding outcome callback as follows:

```ruby
outcomes.handle :successful_booking, appointment
```

In short, this says to process the outcome of :successful_booking with the corresponding handler callback passed in via the outcome_handlers block, and passing that callback the `appointment` object. Again as a side benefit, this makes the intent of the code explicit: we can unambiguously see that our code has determined the outcome of the method at this point, and what exactly that outcome is.

Of course, with any non-trivial business logic, you will have multiple calls to `outcome.handle` for your different outcomes. You might also have multiple paths to get to a specific outcome, or even trigger an outcome within a rescue clause. Outbacker has some protections to help ensure that your controller handles all your outcomes once (and only once), and that your business logic method triggers at least one (and only one) outcome:

* When you trigger an outcome, if you've already handled that outcome, (i.e., if your controller has provided multiple outcome callbacks for the triggered outcome), Outbacker raises an exception.
* When you trigger an outcome, if your controller hasn't provided a callback for that outcome, Outbacker raises an exception.
* If by the conclusion of your Outbacked method (i.e, when the `with(outcome_handlers)` method has finished executing your business logic block), if no outcome at all was triggered, Outbacker raises an exception.
* If your Outbacked method tries to trigger an outcome after one has already been triggered, Outbacker raises an exception.

### Return values

The return value of an Outbacked method is the same as any Ruby method (i.e., the value of the last evaluated expression). However, we typically don't care about return values when using Outbacker. In a sense, the result/return values are the outcome, as well as any values passed as arguments to the outcome block.

However, sometimes you want to invoke your business-logic methods without having to provide a block of outcome callbacks. For example, when invoking these methods within a Rails console/REPL for debugging or support purposes, sometimes it's inconvenient to have to provide callback blocks. You merely want to execute the method, and don't need to act on the outcome—you just want to know the result.

If you don't provide a callback block to an Outbacked method, Outbacker simply returns the outcome key and any arguments, as passed to the `handle` method. So for the following call to the `handle` method:

```ruby
outcomes.handle :successful_booking, appointment
```

When you invoke `AppointmentCalendar#book_appointment(params)` with no outcome callback block, it would simply return `[:successful_booking, appointment]`.


## Testing

When testing controllers (esp. in isolation as opposed to within integrated tests), you typically need to mock or stub your business logic methods in order to return a canned value. However, when using Outbacker, you don't want to simply stub a return value—you need to be able specify that a specific outcome is triggered, so that the corresponding outcome callback provided by your controller is executed. Because the standard mocking libraries can't help you with this, Outbacker provides its own testing support class, `OutbackerStub` to let you "stub" outcomes:

```ruby

# Add this to your test_helper.rb
require 'test_support/outbacker_stub'

...

test "user is redirected to the credits purchase page when they lack sufficient credits" do
  calendar_stub = Outbacker::OutbackerStub.new
  calendar_stub.stub('book_appointment', :insufficient_credits, stubbed_appointment)

  # This is a method we added to our controller to inject dependencies:
  @controller.inject_calendar(calendar_stub)

  post :create, appointment: valid_appointment_params

  assert_redirected_to new_credits_url
end

...

```

Here we've stubbed the `AppointmentCalendar#book_appointment` method, specifying that we want it to trigger the `insufficient_credits` outcome, passing along the `stubbed_appointment object` (created by whatever test double tools you're already using) to our outcome block. You can of course specify any number of objects to be passed by the stubbed method to the outcome block.

Note that this only provides stubbing functionality, with no support for mocking and setting/verifying expectations that methods are invoked by your object under your test. In practice, I haven't found this to be a problem, because these days I find this level of mocking often results in brittle, expensive-to-maintain tests. If you disagree, or have a valid need for mocks, then you can always use an existing mocking library, and write tests to set/verify expectations, distinct from your tests that depend on stubbing. You probably should be doing this anyway if you adhere to the practice of a single assertion per test.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'outbacker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install outbacker

## Usage

Write business logic object, controllers, and tests as described above.

## Contributing

1. Fork it ( https://github.com/polypressure/outbacker/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
