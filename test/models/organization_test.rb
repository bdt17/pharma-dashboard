require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "requires a name" do
    org = Organization.new
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "cannot be destroyed while it still has users" do
    org = Organization.create!(name: "Acme Pharma")
    User.create!(email: "keeper@example.com", password: "password123!", organization: org, role: "admin")

    assert_not org.destroy
    assert_includes org.errors[:base].join, "Cannot delete record"
  end

  test "is assigned a unique referral code on creation" do
    org = Organization.create!(name: "Acme Pharma")
    assert_match(/\A[A-Z0-9]{8}\z/, org.referral_code)
  end

  test "does not overwrite an explicitly set referral code" do
    org = Organization.create!(name: "Acme Pharma", referral_code: "MYCODE1")
    assert_equal "MYCODE1", org.referral_code
  end

  test "find_by_referral_code matches case-insensitively" do
    org = Organization.create!(name: "Acme Pharma", referral_code: "ABC123XY")
    assert_equal org, Organization.find_by_referral_code("abc123xy")
    assert_equal org, Organization.find_by_referral_code(" ABC123XY ")
  end

  test "find_by_referral_code returns nil for a blank or unknown code" do
    assert_nil Organization.find_by_referral_code(nil)
    assert_nil Organization.find_by_referral_code("")
    assert_nil Organization.find_by_referral_code("NOPE0000")
  end

  test "is assigned a unique verification_token on creation" do
    org = Organization.create!(name: "Acme Pharma")
    assert org.verification_token.present?
  end

  test "does not overwrite an explicitly set verification_token" do
    org = Organization.create!(name: "Acme Pharma", verification_token: "my-custom-token")
    assert_equal "my-custom-token", org.verification_token
  end

  test "verified? is false with no subscription" do
    org = Organization.create!(name: "Acme Pharma")
    assert_not org.verified?
  end

  test "verified? is true with an active or trialing subscription" do
    org = Organization.create!(name: "Acme Pharma")
    Subscription.create!(organization: org, status: "trialing", stripe_subscription_id: "sub_123")
    assert org.verified?
  end

  test "verified? is false once the subscription is canceled" do
    org = Organization.create!(name: "Acme Pharma")
    Subscription.create!(organization: org, status: "canceled", stripe_subscription_id: "sub_123")
    assert_not org.verified?
  end

  test "alert_sms_available? on the Pro tier and up of an active subscription" do
    org = Organization.create!(name: "Acme Pharma")
    assert_not org.alert_sms_available?, "no subscription"

    sub = Subscription.create!(organization: org, status: "active", stripe_subscription_id: "sub_1", tier: "starter")
    assert_not org.alert_sms_available?, "starter tier"

    sub.update!(tier: "pro")
    assert org.alert_sms_available?, "pro tier"

    sub.update!(tier: "compliance")
    assert org.alert_sms_available?, "compliance tier"

    sub.update!(tier: "enterprise")
    assert org.alert_sms_available?, "enterprise tier"

    sub.update!(status: "past_due")
    assert_not org.alert_sms_available?, "not active"
  end

  test "webhooks_available? on the Compliance tier and up of an active subscription" do
    org = Organization.create!(name: "Acme Pharma")
    assert_not org.webhooks_available?, "no subscription"

    sub = Subscription.create!(organization: org, status: "active", stripe_subscription_id: "sub_1", tier: "pro")
    assert_not org.webhooks_available?, "pro tier"

    sub.update!(tier: "compliance")
    assert org.webhooks_available?, "compliance tier"

    sub.update!(tier: "enterprise")
    assert org.webhooks_available?, "enterprise tier"

    sub.update!(status: "canceled")
    assert_not org.webhooks_available?, "not active"
  end

  test "webhooks_available? treats a pre-tier subscription as full-featured" do
    org = Organization.create!(name: "Acme Pharma")
    Subscription.create!(organization: org, status: "active", stripe_subscription_id: "sub_legacy", tier: nil)
    assert org.webhooks_available?
  end

  test "card_expiring_soon? tracks the flag CardExpiryCheckJob maintains" do
    org = Organization.create!(name: "Acme Pharma")
    assert_not org.card_expiring_soon?, "no flag"

    org.update!(card_expiry_notified_for: Date.current.strftime("%Y-%m"))
    assert org.card_expiring_soon?, "current-month expiry"

    org.update!(card_expiry_notified_for: 2.months.ago.strftime("%Y-%m"))
    assert org.card_expiring_soon?, "already-lapsed card still warns"

    org.update!(card_expiry_notified_for: 2.years.from_now.strftime("%Y-%m"))
    assert_not org.card_expiring_soon?, "a far-future stale flag does not warn"

    org.update!(card_expiry_notified_for: "garbage")
    assert_not org.card_expiring_soon?
  end

  test "alert_sms_available? treats a pre-tier subscription as full-featured" do
    org = Organization.create!(name: "Acme Pharma")
    Subscription.create!(organization: org, status: "active", stripe_subscription_id: "sub_legacy", tier: nil)
    assert org.alert_sms_available?
  end

  test "time_zone_or_utc falls back to UTC when unset" do
    org = Organization.create!(name: "Acme Pharma")
    assert_equal "UTC", org.time_zone_or_utc.name

    org.update!(time_zone: "Pacific Time (US & Canada)")
    assert_equal "Pacific Time (US & Canada)", org.time_zone_or_utc.name
  end

  test "rejects a time_zone that isn't a real ActiveSupport::TimeZone name" do
    org = Organization.new(name: "Acme Pharma", time_zone: "Mars/Olympus_Mons")
    assert_not org.valid?
    assert_includes org.errors[:time_zone], "is not included in the list"
  end

  test "sms_quiet_hours_active? is always false unless the org opted in" do
    org = Organization.create!(name: "Acme Pharma", time_zone: "UTC")
    assert_not org.sms_quiet_hours_active?(Time.utc(2026, 1, 1, 2, 0)) # 2am UTC, would be quiet if enabled
  end

  test "sms_quiet_hours_active? covers both sides of the midnight wrap, in the org's own timezone" do
    org = Organization.create!(name: "Acme Pharma", time_zone: "UTC", sms_quiet_hours_enabled: true)

    assert org.sms_quiet_hours_active?(Time.utc(2026, 1, 1, 22, 0))   # 10pm -- evening side
    assert org.sms_quiet_hours_active?(Time.utc(2026, 1, 1, 3, 0))    # 3am -- small-hours side
    assert_not org.sms_quiet_hours_active?(Time.utc(2026, 1, 1, 12, 0)) # noon
    assert_not org.sms_quiet_hours_active?(Time.utc(2026, 1, 1, 7, 0))  # exactly the end boundary
    assert org.sms_quiet_hours_active?(Time.utc(2026, 1, 1, 21, 0))     # exactly the start boundary
  end

  test "sms_quiet_hours_active? respects a non-UTC timezone, not just wall-clock UTC hour" do
    # 9pm UTC = 1pm Pacific (UTC-8 in January) -- broad daylight there,
    # so quiet hours must not trigger off the raw UTC hour.
    org = Organization.create!(name: "Acme Pharma", time_zone: "Pacific Time (US & Canada)", sms_quiet_hours_enabled: true)
    assert_not org.sms_quiet_hours_active?(Time.utc(2026, 1, 1, 21, 0))
  end

  test "sms_quiet_hours_end_at picks tonight's or tomorrow's end depending on which side of midnight" do
    org = Organization.create!(name: "Acme Pharma", time_zone: "UTC", sms_quiet_hours_enabled: true)

    # 10pm on the 1st -> still-tonight's window ends the *next* morning.
    assert_equal Time.utc(2026, 1, 2, 7, 0), org.sms_quiet_hours_end_at(Time.utc(2026, 1, 1, 22, 0))
    # 3am on the 1st -> the window that started last night ends *this* morning.
    assert_equal Time.utc(2026, 1, 1, 7, 0), org.sms_quiet_hours_end_at(Time.utc(2026, 1, 1, 3, 0))
  end
end
