require "test_helper"

class SmsExcursionResolvedJobTest < ActiveJob::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @vehicle = Vehicle.create!(name: "PHX-001", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-9", vehicle: @vehicle, organization: @organization, status: "active")
    @event = ExcursionEvent.create!(
      batch: @batch, vehicle: @vehicle,
      started_at: Time.utc(2026, 8, 31, 2, 15), ended_at: Time.utc(2026, 8, 31, 3, 0),
      trigger_temp: 14.2, peak_temp: 14.2
    )
  end

  test "sends one message announcing the resolution" do
    captured = {}
    SmsSender.stub(:deliver, ->(to:, body:) { captured = { to: to, body: body }; "SM1" }) do
      SmsExcursionResolvedJob.perform_now(@event.id, "+14155550100")
    end

    assert_equal "+14155550100", captured[:to]
    assert_match "all clear", captured[:body]
    assert_match "LOT-9", captured[:body]
    assert_match "back in range", captured[:body]
    assert_match "PHX-001", captured[:body]
  end

  test "logs and does not raise when Twilio isn't configured" do
    SmsSender.stub(:deliver, ->(**) { raise SmsSender::NotConfigured, "no keys" }) do
      assert_nothing_raised do
        SmsExcursionResolvedJob.perform_now(@event.id, "+14155550100")
      end
    end
  end

  test "does nothing if the excursion event has since been deleted" do
    @event.destroy
    called = false
    SmsSender.stub(:deliver, ->(**) { called = true }) do
      SmsExcursionResolvedJob.perform_now(@event.id, "+14155550100")
    end
    assert_not called
  end
end
