require "test_helper"

class TwoFactor::SetupControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  def create_user(role:)
    User.create!(
      email: "#{role}@example.com", password: "password123!",
      organization: @organization, role: role
    )
  end

  test "an un-enrolled user is shown the setup page with a secret and QR code" do
    user = create_user(role: "dispatcher")
    sign_in user

    get two_factor_setup_path

    assert_response :success
    assert user.reload.otp_secret.present?
    assert_includes response.body, user.otp_secret
    assert_includes response.body, "<svg"
  end

  test "a wrong code re-renders the page and does not enable two-factor" do
    user = create_user(role: "dispatcher")
    sign_in user

    get two_factor_setup_path
    post two_factor_setup_path, params: { otp_code: "000000" }

    assert_response :unprocessable_content
    assert_not user.reload.otp_enabled?
  end

  test "a correct code enables two-factor and shows the backup codes" do
    user = create_user(role: "dispatcher")
    sign_in user

    get two_factor_setup_path
    post two_factor_setup_path, params: { otp_code: ROTP::TOTP.new(user.reload.otp_secret).now }
    assert_redirected_to two_factor_backup_codes_path

    assert user.reload.otp_enabled?
    assert_equal 10, user.backup_codes_remaining

    follow_redirect!
    assert_select "li", minimum: 10
  end

  test "an enrolled user sees the management page, not the enrollment form" do
    user = create_user(role: "dispatcher")
    user.enable_two_factor!
    sign_in user

    get two_factor_setup_path

    assert_response :success
    assert_includes response.body, "Two-factor authentication is on"
  end

  test "an opt-in user can turn two-factor off with a valid code" do
    user = create_user(role: "dispatcher")
    user.generate_otp_secret!
    user.enable_two_factor!
    sign_in user

    delete two_factor_setup_path, params: { otp_code: ROTP::TOTP.new(user.otp_secret).now }

    assert_redirected_to dashboard_path
    assert_not user.reload.otp_enabled?
  end

  test "a required-role user cannot turn two-factor off" do
    user = create_user(role: "admin")
    user.generate_otp_secret!
    user.enable_two_factor!
    code = ROTP::TOTP.new(user.otp_secret).now
    sign_in user

    delete two_factor_setup_path, params: { otp_code: code }

    assert_redirected_to two_factor_setup_path
    assert user.reload.otp_enabled?
  end
end
