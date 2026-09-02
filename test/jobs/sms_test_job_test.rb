require "test_helper"

class SmsTestJobTest < ActiveJob::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @recipient = @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")
  end

  test "sends a test message to the recipient's number" do
    captured = {}
    SmsSender.stub(:deliver, ->(to:, body:) { captured = { to: to, body: body } }) do
      SmsTestJob.perform_now(@recipient.id)
    end

    assert_equal "+14155550100", captured[:to]
    assert_match "test alert for Acme Pharma", captured[:body]
  end

  test "logs and does not raise when Twilio isn't configured" do
    SmsSender.stub(:deliver, ->(**) { raise SmsSender::NotConfigured, "no keys" }) do
      assert_nothing_raised { SmsTestJob.perform_now(@recipient.id) }
    end
  end

  test "does nothing if the recipient was deleted" do
    id = @recipient.id
    @recipient.destroy
    called = false
    SmsSender.stub(:deliver, ->(**) { called = true }) do
      SmsTestJob.perform_now(id)
    end
    assert_not called
  end
end
