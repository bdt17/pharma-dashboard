require "test_helper"

class TwoFactor::SetupControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "enrollee@example.com", password: "password123!",
      organization: Organization.create!(name: "Acme Pharma"), role: "admin"
    )
    sign_in @user
  end

  test "an un-enrolled user is shown the setup page with a secret and QR code" do
    get two_factor_setup_path

    assert_response :success
    assert @user.reload.otp_secret.present?
    assert_includes response.body, @user.otp_secret
    assert_includes response.body, "<svg"
  end

  test "a wrong code re-renders the page and does not enable two-factor" do
    get two_factor_setup_path # assigns the secret
    post two_factor_setup_path, params: { otp_code: "000000" }

    assert_response :unprocessable_content
    assert_not @user.reload.otp_enabled?
  end

  test "a correct code enables two-factor and shows the backup codes" do
    get two_factor_setup_path
    code = ROTP::TOTP.new(@user.reload.otp_secret).now

    post two_factor_setup_path, params: { otp_code: code }
    assert_redirected_to two_factor_backup_codes_path

    assert @user.reload.otp_enabled?
    assert_equal 10, @user.backup_codes_remaining

    follow_redirect!
    assert_response :success
    assert_select "li", minimum: 10
  end

  test "an already-enrolled, verified user is redirected away from setup" do
    @user.enable_two_factor!
    get two_factor_setup_path
    assert_redirected_to dashboard_path
  end
end
