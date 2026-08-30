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

    private

    def group(name) = Ops::Diagnostics.call.find { |g| g.name == name }
    def email_check(label) = group("Email").checks.find { |c| c.label == label }
    def billing_check(label) = group("Billing (Stripe)").checks.find { |c| c.label == label }

    def with_env(overrides)
      original = ENV.to_h
      overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
      yield
    ensure
      ENV.replace(original)
    end
  end
end
