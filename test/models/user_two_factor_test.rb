require "test_helper"

class UserTwoFactorTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "totp@example.com", password: "password123!",
      organization: Organization.create!(name: "Acme Pharma"), role: "admin"
    )
    @user.generate_otp_secret!
    @totp = ROTP::TOTP.new(@user.otp_secret, issuer: TwoFactorAuthentication::TOTP_ISSUER)
  end

  test "generate_otp_secret! assigns a secret and is a no-op once enabled" do
    assert @user.otp_secret.present?

    @user.enable_two_factor!
    secret = @user.otp_secret
    @user.generate_otp_secret!
    assert_equal secret, @user.reload.otp_secret
  end

  test "otp_provisioning_uri carries the issuer and account" do
    uri = @user.otp_provisioning_uri
    assert_includes uri, "otpauth://totp/"
    assert_includes uri, ERB::Util.url_encode("totp@example.com")
    assert_includes uri, "issuer=Pharma%20Transport"
    assert_includes uri, "secret=#{@user.otp_secret}"
  end

  test "verify_and_consume_otp! accepts a current code and then rejects its replay" do
    code = @totp.now
    assert @user.verify_and_consume_otp!(code)
    assert_not @user.verify_and_consume_otp!(code), "the same code must not work twice"
  end

  test "verify_and_consume_otp! rejects a wrong code" do
    assert_not @user.verify_and_consume_otp!("000000")
    assert_not @user.verify_and_consume_otp!(nil)
  end

  test "enable_two_factor! flips the flag and returns ten one-time backup codes" do
    codes = @user.enable_two_factor!

    assert @user.reload.otp_enabled?
    assert_equal 10, codes.size
    assert_equal 10, codes.uniq.size
    assert_equal 10, @user.backup_codes_remaining
  end

  test "a backup code works exactly once" do
    codes = @user.enable_two_factor!

    assert @user.invalidate_backup_code!(codes.first)
    assert_not @user.invalidate_backup_code!(codes.first)
    assert_equal 9, @user.reload.backup_codes_remaining
  end

  test "verify_second_factor accepts either a TOTP or a backup code" do
    codes = @user.enable_two_factor!

    assert @user.verify_second_factor(@totp.now)
    assert @user.verify_second_factor(codes.last)
    assert_not @user.verify_second_factor("nope")
  end
end
