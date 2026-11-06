require "test_helper"
require "fugit"

class OnboardingEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @now = Time.utc(2026, 11, 10, 16)
    @org = Organization.create!(name: "Main Street Rx", created_at: @now - 26.hours)
    @admin = User.create!(email: "owner@example.com", password: "password123!", organization: @org, role: "admin")
    User.create!(email: "driver@example.com", password: "password123!", organization: @org, role: "driver")
  end

  def run_job = OnboardingEmailJob.perform_now(now: @now)

  test "sends the day-1 nudge to admins only, once" do
    assert_enqueued_emails 1 do
      run_job
    end
    assert_equal 1, @org.reload.onboarding_emails_sent

    assert_no_enqueued_emails { run_job }
  end

  test "nothing before a day has passed" do
    @org.update!(created_at: @now - 20.hours)
    assert_no_enqueued_emails { run_job }
  end

  test "sends day 3 and day 7 at their offsets, and only the latest when days were missed" do
    @org.update!(created_at: @now - 8.days)
    assert_enqueued_emails 1 do
      run_job
    end
    assert_equal 3, @org.reload.onboarding_emails_sent
    assert_no_enqueued_emails { run_job }
  end

  test "stops once the org is fully activated" do
    vehicle = Vehicle.create!(name: "Van", organization: @org)
    batch = Batch.create!(lot_number: "LOT-1", vehicle: vehicle, organization: @org)
    ComplianceReport.create!(batch: batch, organization: @org, generated_by: @admin, version: 1, content_hash: "a" * 64, pdf_data: "%PDF-fake")
    assert_no_enqueued_emails { run_job }
  end

  test "skips internal orgs, old orgs, and unsubscribed admins" do
    @org.update!(internal: true)
    assert_no_enqueued_emails { run_job }

    @org.update!(internal: false, created_at: @now - 30.days)
    assert_no_enqueued_emails { run_job }

    @org.update!(created_at: @now - 26.hours)
    EmailSuppression.create!(email: @admin.email)
    assert_no_enqueued_emails { run_job }
  end

  test "sends the trial notice once, three days out" do
    @org.update!(created_at: @now - 20.days, onboarding_emails_sent: 3)
    sub = Subscription.create!(organization: @org, status: "trialing", current_period_end: @now + 2.days)

    assert_enqueued_emails 1 do
      run_job
    end
    assert sub.reload.trial_ending_notified_at
    assert_no_enqueued_emails { run_job }
  end

  test "no trial notice when the trial is further out or the sub is active" do
    @org.update!(created_at: @now - 20.days, onboarding_emails_sent: 3)
    Subscription.create!(organization: @org, status: "trialing", current_period_end: @now + 6.days)
    Subscription.create!(organization: @org, status: "active", current_period_end: @now + 1.day)
    assert_no_enqueued_emails { run_job }
  end

  test "the schedule parses to 9am Phoenix daily" do
    task = YAML.load_file(Rails.root.join("config/recurring.yml"))["production"]["onboarding_emails"]
    assert_equal "OnboardingEmailJob", task["class"]
    assert_equal "0 9 * * * America/Phoenix", Fugit.parse(task["schedule"]).to_cron_s
  end
end
