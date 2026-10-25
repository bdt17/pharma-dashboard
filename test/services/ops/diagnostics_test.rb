require "test_helper"

module Ops
  class DiagnosticsTest < ActiveSupport::TestCase
    test "returns the expected groups, each with checks" do
      groups = Ops::Diagnostics.call

      names = groups.map(&:name)
      assert_includes names, "Email"
      assert_includes names, "Billing (Stripe)"
      assert_includes names, "Application"
      assert groups.all? { |g| g.checks.any? }
      assert groups.flat_map(&:checks).all? { |c| %i[ok warn error].include?(c.status) }
    end

    test "email group flags a missing delivery method as an error" do
      with_env("POSTMARK_API_TOKEN" => nil, "SMTP_ADDRESS" => nil) do
        check = email_check("Delivery method")
        assert_equal :error, check.status
        assert_match "discarded", check.detail
      end
    end

    test "email group is ok when SMTP_ADDRESS and a real APP_HOST are set" do
      with_env("POSTMARK_API_TOKEN" => nil, "SMTP_ADDRESS" => "smtp.resend.com", "APP_HOST" => "pharmatransport.org") do
        assert_equal :ok, email_check("Delivery method").status
        assert_match "SMTP via smtp.resend.com", email_check("Delivery method").detail
        assert_equal :ok, email_check("Mail link host (APP_HOST)").status
      end
    end

    test "email group reports Postmark, and prefers it over SMTP, when POSTMARK_API_TOKEN is set" do
      with_env("POSTMARK_API_TOKEN" => "pm_secret_token", "SMTP_ADDRESS" => "smtp.office365.com") do
        check = email_check("Delivery method")
        assert_equal :ok, check.status
        assert_equal "Postmark API", check.detail
      end
    end

    test "email group never prints the Postmark token, only whether it's set" do
      with_env("POSTMARK_API_TOKEN" => "pm_secret_token") do
        details = group("Email").checks.map(&:detail).join(" ")
        assert_not_includes details, "pm_secret_token"
      end
    end

    test "billing group flags a missing webhook secret as an error" do
      with_env("STRIPE_WEBHOOK_SECRET" => nil) do
        check = billing_check("Webhook secret (STRIPE_WEBHOOK_SECRET)")
        assert_equal :error, check.status
      end
    end

    test "SMS group warns when Twilio is unconfigured and is ok when all three vars are set" do
      with_env("TWILIO_ACCOUNT_SID" => nil, "TWILIO_AUTH_TOKEN" => nil, "TWILIO_MESSAGING_FROM" => nil) do
        assert_equal :warn, sms_check("Overall").status
      end

      with_env("TWILIO_ACCOUNT_SID" => "AC123", "TWILIO_AUTH_TOKEN" => "tok", "TWILIO_MESSAGING_FROM" => "MG999") do
        assert_equal :ok, sms_check("Overall").status
        assert_match "Messaging Service", sms_check("Sender (TWILIO_MESSAGING_FROM)").detail
      end
    end

    test "SMS group never prints the env values, only whether they're set" do
      with_env("TWILIO_ACCOUNT_SID" => "AC_secret_value", "TWILIO_AUTH_TOKEN" => "tok_secret", "TWILIO_MESSAGING_FROM" => "+15551234567") do
        details = group("SMS alerts (Twilio)").checks.map(&:detail).join(" ")
        assert_not_includes details, "AC_secret_value"
        assert_not_includes details, "tok_secret"
        assert_not_includes details, "+15551234567"
      end
    end

    test "billing group reports overage opt-ins and this month's extra packets" do
      org = Organization.create!(name: "Acme", overage_billing_enabled: true)
      vehicle = Vehicle.create!(name: "T", organization: org)
      batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: vehicle, organization: org)
      admin = User.create!(email: "a@acme.test", password: "password123!", organization: org, role: "admin")
      report = ComplianceReport.create_next_version!(batch: batch, generated_by: admin, content_hash: SecureRandom.hex(32), pdf_data: "%PDF")
      PacketOverage.create!(organization: org, compliance_report: report, stripe_invoice_item_id: "ii_1", amount_cents: 14_900)

      detail = billing_check("Overage billing").detail
      assert_match "1 org opted in", detail
      assert_match "1 extra packet this month", detail
      assert_match "$149.00", detail
    end

    test "billing group warns when a card is flagged as expiring soon" do
      Organization.create!(name: "Acme", card_expiry_notified_for: Date.current.strftime("%Y-%m"))
      assert_equal :warn, billing_check("Cards expiring soon").status
    end

    test "activity group summarizes acquisition sources for the last 7 days" do
      2.times { DscsaAssessment.create!(answers: {}, score: 50, band: "progressing", utm_source: "google", utm_campaign: "dscsa-nov") }
      DscsaAssessment.create!(answers: {}, score: 50, band: "progressing")

      detail = activity_check("Acquisition sources (7d)").detail
      assert_match "3 total", detail
      assert_match "google/dscsa-nov: 2", detail
      assert_match "direct/unknown: 1", detail
    end

    test "activity group reports no assessments yet when there's none in the window" do
      assert_equal "no assessments yet", activity_check("Acquisition sources (7d)").detail
    end

    test "webhooks group flags auto-disabled endpoints" do
      org = Organization.create!(name: "Acme")
      org.webhook_endpoints.create!(url: "https://8.8.8.8/ok")
      org.webhook_endpoints.create!(url: "https://8.8.8.8/dead", active: false,
                                    consecutive_failures: WebhookEndpoint::AUTO_DISABLE_AFTER)

      assert_equal "1 active of 2", webhooks_check("Endpoints").detail
      assert_equal :warn, webhooks_check("Auto-disabled (failed #{WebhookEndpoint::AUTO_DISABLE_AFTER}x)").status
    end

    test "application group warns when SENTRY_DSN is unset and is ok when it's set" do
      with_env("SENTRY_DSN" => nil) do
        check = app_check("Error tracking (SENTRY_DSN)")
        assert_equal :warn, check.status
        assert_match "unset", check.detail
      end

      with_env("SENTRY_DSN" => "https://key@o0.ingest.sentry.io/0") do
        assert_equal :ok, app_check("Error tracking (SENTRY_DSN)").status
      end
    end

    test "application group warns when Google Ads conversion tracking is unset and reports labelled events when set" do
      label = "Google Ads conversion tracking (GOOGLE_ADS_CONVERSION_ID)"

      with_env("GOOGLE_ADS_CONVERSION_ID" => nil) do
        assert_equal :warn, app_check(label).status
        assert_match "unset", app_check(label).detail
      end

      with_env("GOOGLE_ADS_CONVERSION_ID" => "AW-123456789",
               "GOOGLE_ADS_LABEL_ASSESSMENT" => "abc", "GOOGLE_ADS_LABEL_TRIAL" => "def",
               "GOOGLE_ADS_LABEL_CALL" => nil) do
        assert_equal :ok, app_check(label).status
        assert_match "2/3 conversion events labelled", app_check(label).detail
      end
    end

    test "application group never prints the Google Ads ids, only whether they're set" do
      with_env("GOOGLE_ADS_CONVERSION_ID" => "AW-secretaccount", "GOOGLE_ADS_LABEL_TRIAL" => "secretlabel") do
        details = group("Application").checks.map(&:detail).join(" ")
        assert_not_includes details, "AW-secretaccount"
        assert_not_includes details, "secretlabel"
      end
    end

    private

    def group(name) = Ops::Diagnostics.call.find { |g| g.name == name }
    def email_check(label) = group("Email").checks.find { |c| c.label == label }
    def billing_check(label) = group("Billing (Stripe)").checks.find { |c| c.label == label }
    def sms_check(label) = group("SMS alerts (Twilio)").checks.find { |c| c.label == label }
    def webhooks_check(label) = group("Outbound webhooks").checks.find { |c| c.label == label }
    def app_check(label) = group("Application").checks.find { |c| c.label == label }
    def activity_check(label) = group("Recent activity").checks.find { |c| c.label == label }

    def with_env(overrides)
      original = ENV.to_h
      overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
      yield
    ensure
      ENV.replace(original)
    end
  end
end
