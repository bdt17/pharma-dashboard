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

  test "quiet hours delay the SMS to the end of the window, in the org's own timezone" do
    subscribe("pro")
    @organization.update!(time_zone: "UTC", sms_quiet_hours_enabled: true)
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")

    travel_to Time.utc(2026, 1, 1, 2, 0) do # 2am UTC -- inside the quiet window
      ExcursionNotifier.alert(@event)
    end

    job = enqueued_jobs.find { |j| j["job_class"] == "SmsExcursionAlertJob" }
    assert_equal Time.utc(2026, 1, 1, 7, 0).to_i, job["scheduled_at"].to_time.to_i
  end

  test "quiet hours off (default) never delays the SMS, even at 2am" do
    subscribe("pro")
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")

    travel_to Time.utc(2026, 1, 1, 2, 0) do
      ExcursionNotifier.alert(@event)
    end

    job = enqueued_jobs.find { |j| j["job_class"] == "SmsExcursionAlertJob" }
    assert_nil job["scheduled_at"]
  end

  test "quiet hours enabled but outside the window sends immediately" do
    subscribe("pro")
    @organization.update!(time_zone: "UTC", sms_quiet_hours_enabled: true)
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")

    travel_to Time.utc(2026, 1, 1, 12, 0) do # noon -- outside the window
      ExcursionNotifier.alert(@event)
    end

    job = enqueued_jobs.find { |j| j["job_class"] == "SmsExcursionAlertJob" }
    assert_nil job["scheduled_at"]
  end

  test "alert enqueues no SMS on a Pro plan with no recipients" do
    subscribe("pro")

    assert_no_enqueued_jobs only: SmsExcursionAlertJob do
      ExcursionNotifier.alert(@event)
    end
  end

  test "resolved emails only -- no all-clear SMS unless the org opted in" do
    subscribe("pro")
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")

    assert_enqueued_emails 1 do
      assert_no_enqueued_jobs only: SmsExcursionResolvedJob do
        ExcursionNotifier.resolved(@event)
      end
    end
  end

  test "resolved sends an all-clear SMS once the org opts in" do
    subscribe("pro")
    @organization.update!(all_clear_sms_enabled: true)
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")
    @organization.alert_recipients.create!(label: "Backup", phone: "+14155550101")

    assert_enqueued_jobs 2, only: SmsExcursionResolvedJob do
      ExcursionNotifier.resolved(@event)
    end
  end

  test "the all-clear opt-in still requires an SMS-eligible plan" do
    @organization.update!(all_clear_sms_enabled: true) # no subscription at all
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")

    assert_no_enqueued_jobs only: SmsExcursionResolvedJob do
      ExcursionNotifier.resolved(@event)
    end
  end

  test "quiet hours delay the all-clear text the same way they delay the original alert" do
    subscribe("pro")
    @organization.update!(all_clear_sms_enabled: true, time_zone: "UTC", sms_quiet_hours_enabled: true)
    @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")

    travel_to Time.utc(2026, 1, 1, 2, 0) do # inside the quiet window
      ExcursionNotifier.resolved(@event)
    end

    job = enqueued_jobs.find { |j| j["job_class"] == "SmsExcursionResolvedJob" }
    assert_equal Time.utc(2026, 1, 1, 7, 0).to_i, job["scheduled_at"].to_time.to_i
  end

  test "publishes excursion.started / .resolved webhooks on the Compliance plan" do
    subscribe("compliance")
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/hook")

    assert_enqueued_jobs 1, only: WebhookDeliveryJob do
      ExcursionNotifier.alert(@event)
    end
    assert_enqueued_jobs 1, only: WebhookDeliveryJob do
      ExcursionNotifier.resolved(@event)
    end
  end

  test "no webhook without the Compliance plan" do
    subscribe("pro")
    @organization.webhook_endpoints.create!(url: "https://8.8.8.8/hook")

    assert_no_enqueued_jobs only: WebhookDeliveryJob do
      ExcursionNotifier.alert(@event)
    end
  end
end
