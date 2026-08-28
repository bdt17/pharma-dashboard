require "test_helper"

class TwoFactor::ChallengeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "enrolled@example.com", password: "password123!",
      organization: Organization.create!(name: "Acme Pharma"), role: "admin"
    )
    @user.generate_otp_secret!
    @backup_codes = @user.enable_two_factor!
    @totp = ROTP::TOTP.new(@user.otp_secret)

    # Real login so the "mfa_passed" marker is cleared and the challenge is
    # actually required (mirrors production; see config/initializers/two_factor.rb).
    post user_session_path, params: { user: { email: @user.email, password: "password123!" } }
  end

  test "the challenge is required before any authenticated page" do
    get dashboard_path
    assert_redirected_to new_two_factor_challenge_path
  end

  test "a valid TOTP clears the challenge and reaches the dashboard" do
    post two_factor_challenge_path, params: { otp_code: @totp.now }
    assert_redirected_to dashboard_path

    get dashboard_path
    assert_response :success
  end

  test "a backup code works once, then is spent" do
    code = @backup_codes.first

    post two_factor_challenge_path, params: { otp_code: code }
    assert_redirected_to dashboard_path

    # New login -> challenge required again; the same backup code must now fail.
    delete destroy_user_session_path
    post user_session_path, params: { user: { email: @user.email, password: "password123!" } }
    post two_factor_challenge_path, params: { otp_code: code }
    assert_response :unprocessable_content
  end

  test "a wrong code is rejected with 422" do
    post two_factor_challenge_path, params: { otp_code: "000000" }
    assert_response :unprocessable_content
    get dashboard_path
    assert_redirected_to new_two_factor_challenge_path
  end
end
