require "test_helper"

class TwoFactorResetTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(
      email: "Locked.Out@Example.com", password: "password123!",
      organization: @organization, role: "admin"
    )
    @user.generate_otp_secret!
    @user.enable_two_factor!
  end

  test "clears the secret, backup codes, and enabled flag" do
    result = TwoFactorReset.call(email: @user.email)

    @user.reload
    assert_not @user.otp_enabled?
    assert_nil @user.otp_secret
    assert_equal 0, @user.backup_codes_remaining
    assert result.was_enabled
    assert_equal @user, result.user
  end

  test "records an audit entry against the affected user" do
    assert_difference "AuditLog.count", 1 do
      TwoFactorReset.call(email: @user.email, performed_by: "rake:two_factor:reset")
    end

    entry = AuditLog.order(:created_at).last
    assert_equal "two_factor_reset", entry.event
    assert_equal @user, entry.user
    assert_equal "rake:two_factor:reset", entry.data["performed_by"]
    assert_equal true, entry.data["was_enabled"]
    assert_equal "admin", entry.data["role"]
  end

  test "matches the email case-insensitively" do
    result = TwoFactorReset.call(email: "locked.out@example.com")
    assert_equal @user, result.user
  end

  test "works on a user who was only mid-enrollment" do
    other = User.create!(
      email: "midway@example.com", password: "password123!",
      organization: @organization, role: "dispatcher"
    )
    other.generate_otp_secret! # has a secret but never confirmed a code

    result = TwoFactorReset.call(email: other.email)

    assert_not result.was_enabled
    assert_nil other.reload.otp_secret
  end

  test "raises for an unknown email" do
    assert_raises(TwoFactorReset::UserNotFound) do
      TwoFactorReset.call(email: "nobody@example.com")
    end
    assert_raises(TwoFactorReset::UserNotFound) do
      TwoFactorReset.find_user!("  ")
    end
  end
end
