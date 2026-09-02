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

    test "email group flags a missing SMTP_ADDRESS as an error" do
      with_env("SMTP_ADDRESS" => nil) do
        check = email_check("Delivery method")
        assert_equal :error, check.status
        assert_match "discarded", check.detail
      end
    end

    test "email group is ok when SMTP_ADDRESS and a real APP_HOST are set" do
      with_env("SMTP_ADDRESS" => "smtp.resend.com", "APP_HOST" => "pharmatransport.org") do
        assert_equal :ok, email_check("Delivery method").status
        assert_equal :ok, email_check("Mail link host (APP_HOST)").status
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

    test "webhooks group flags auto-disabled endpoints" do
      org = Organization.create!(name: "Acme")
      org.webhook_endpoints.create!(url: "https://8.8.8.8/ok")
      org.webhook_endpoints.create!(url: "https://8.8.8.8/dead", active: false,
                                    consecutive_failures: WebhookEndpoint::AUTO_DISABLE_AFTER)

      assert_equal "1 active of 2", webhooks_check("Endpoints").detail
      assert_equal :warn, webhooks_check("Auto-disabled (failed #{WebhookEndpoint::AUTO_DISABLE_AFTER}x)").status
    end

    private

    def group(name) = Ops::Diagnostics.call.find { |g| g.name == name }
    def email_check(label) = group("Email").checks.find { |c| c.label == label }
    def billing_check(label) = group("Billing (Stripe)").checks.find { |c| c.label == label }
    def sms_check(label) = group("SMS alerts (Twilio)").checks.find { |c| c.label == label }
    def webhooks_check(label) = group("Outbound webhooks").checks.find { |c| c.label == label }

    def with_env(overrides)
      original = ENV.to_h
      overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
      yield
    ensure
      ENV.replace(original)
    end
  end
end
