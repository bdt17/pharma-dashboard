require "test_helper"

# Exercises the real gate (ApplicationController#enforce_two_factor) by driving
# an actual password login rather than Devise::Test's sign_in helper.
class TwoFactorEnforcementTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(
      email: "user@example.com", password: "password123!",
      organization: @organization, role: "admin"
    )
  end

  def log_in
    post user_session_path, params: { user: { email: @user.email, password: "password123!" } }
  end

  test "an un-enrolled user is forced into two-factor setup after login" do
    log_in
    get dashboard_path
    assert_redirected_to two_factor_setup_path
  end

  test "an enrolled user must pass the challenge before reaching an authenticated page" do
    @user.generate_otp_secret!
    @user.enable_two_factor!

    log_in
    get dashboard_path
    assert_redirected_to new_two_factor_challenge_path

    post two_factor_challenge_path, params: { otp_code: ROTP::TOTP.new(@user.otp_secret).now }
    get dashboard_path
    assert_response :success
  end

  test "signing in again re-triggers the challenge in the same browser session" do
    @user.generate_otp_secret!
    @user.enable_two_factor!
    totp = ROTP::TOTP.new(@user.otp_secret)

    log_in
    post two_factor_challenge_path, params: { otp_code: totp.now }
    get dashboard_path
    assert_response :success

    delete destroy_user_session_path
    log_in
    get dashboard_path
    assert_redirected_to new_two_factor_challenge_path
  end

  test "JSON API requests are not redirected by the HTML two-factor gate" do
    @user.generate_otp_secret!
    @user.enable_two_factor!
    Vehicle.create!(name: "Truck 1", organization: @organization)

    log_in
    get "/api/v1/vehicles", headers: { "Accept" => "application/json" }

    assert_response :success
    assert_equal "application/json", response.media_type
  end
end
