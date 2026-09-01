require "test_helper"

class ExcursionNotifierTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @vehicle = Vehicle.create!(name: "PHX-001", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-9", vehicle: @vehicle, organization: @organization, status: "active")
    @event = ExcursionEvent.create!(batch: @batch, vehicle: @vehicle, started_at: Time.current, trigger_temp: 14.0, peak_temp: 14.0)
  end

  def subscribe(tier)
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_#{tier}", tier: tier)
  end

  test "alert always emails, and enqueues no SMS without an eligible plan" do
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")

    assert_enqueued_emails 1 do
      assert_no_enqueued_jobs only: SmsExcursionAlertJob do
        ExcursionNotifier.alert(@event)
      end
    end
  end

  test "alert enqueues one SMS job per active recipient on a Pro plan" do
    subscribe("pro")
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")
    @organization.alert_recipients.create!(label: "Backup", phone: "+14155550101")
    @organization.alert_recipients.create!(label: "Off", phone: "+14155550102", active: false)

    assert_enqueued_jobs 2, only: SmsExcursionAlertJob do
      ExcursionNotifier.alert(@event)
    end
  end

  test "alert enqueues no SMS on a Pro plan with no recipients" do
    subscribe("pro")

    assert_no_enqueued_jobs only: SmsExcursionAlertJob do
      ExcursionNotifier.alert(@event)
    end
  end

  test "resolved emails only -- never SMS" do
    subscribe("pro")
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")

    assert_enqueued_emails 1 do
      assert_no_enqueued_jobs only: SmsExcursionAlertJob do
        ExcursionNotifier.resolved(@event)
      end
    end
  end
end
