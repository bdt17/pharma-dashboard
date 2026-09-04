require "test_helper"

class ApplicationMailDeliveryJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  def build_call_request
    CallRequest.create!(name: "Dana Rx", email: "dana@example.com", pharmacy_name: "Dana Pharmacy", topic: "general", message: "hi")
  end

  # Swaps Rails.logger for one backed by a StringIO for the duration of the
  # block, and returns everything written to it -- there's no existing
  # test-suite helper for this, so it's built inline here.
  def capture_log
    io = StringIO.new
    previous_logger = Rails.logger
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = previous_logger
  end

  test "a normal send behaves exactly like the default delivery job" do
    call_request = build_call_request

    assert_emails 1 do
      ApplicationMailDeliveryJob.new.perform("CallRequestMailer", "notify", "deliver_now", args: [ call_request ])
    end
  end

  test "a delivery failure is logged, not raised, and doesn't touch the job queue" do
    call_request = build_call_request

    # A plain double, not a stub on the real MessageDelivery/Mail::Message
    # (a Delegator) -- stubbing methods directly on a Delegator instance
    # doesn't reliably land on the right object.
    failing_delivery = Object.new
    def failing_delivery.deliver_now!
      raise Net::SMTPAuthenticationError, "535 authentication failed"
    end

    log_output = nil
    CallRequestMailer.stub :notify, failing_delivery do
      log_output = capture_log do
        assert_nothing_raised do
          ApplicationMailDeliveryJob.new.perform("CallRequestMailer", "notify", "deliver_now", args: [ call_request ])
        end
      end
    end

    assert_match "[ApplicationMailDeliveryJob] CallRequestMailer#notify failed to send", log_output
    assert_match "Net::SMTPAuthenticationError", log_output
    assert_match "535 authentication failed", log_output
  end

  test "an error building the message (not sending it) still propagates normally" do
    assert_raises(NoMethodError) do
      ApplicationMailDeliveryJob.new.perform("CallRequestMailer", "not_a_real_mailer_method", "deliver_now", args: [])
    end
  end
end
