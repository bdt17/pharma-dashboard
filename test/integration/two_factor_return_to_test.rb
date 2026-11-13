require "test_helper"

# After the two-factor gate stops someone, setup (or the challenge) sends
# them back to what they were doing -- same-site paths only.
class TwoFactorReturnToTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Main Street Rx")
    @admin = User.create!(email: "owner@example.com", password: "password123!", organization: @org, role: "admin")
  end

  def log_in(user = @admin)
    post user_session_path, params: { user: { email: user.email, password: "password123!" } }
  end

  def enroll
    get two_factor_setup_path
    post two_factor_setup_path, params: { otp_code: ROTP::TOTP.new(@admin.reload.otp_secret).now }
    follow_redirect!
  end

  test "a blocked form submission returns to the form after setup" do
    log_in
    post vehicles_path, params: { vehicle: { name: "Van" } }, headers: { "Referer" => "http://www.example.com/vehicles/new" }
    assert_redirected_to two_factor_setup_path
    enroll
    assert_select "a[href=?]", "/vehicles/new", text: /Continue/
  end

  test "a blocked page returns to that page after setup" do
    Vehicle.create!(name: "Van", organization: @org) # real data: the gate applies to every page
    log_in
    get team_path
    assert_redirected_to two_factor_setup_path
    enroll
    assert_select "a[href=?]", "/team", text: /Continue/
  end

  test "an off-site referer is never used" do
    log_in
    post vehicles_path, params: { vehicle: { name: "Van" } }, headers: { "Referer" => "https://evil.example/phish" }
    enroll
    assert_select "a[href=?]", "/dashboard", text: /Continue/
  end

  test "an enrolled user returns to the page they asked for after the challenge" do
    @admin.generate_otp_secret!
    @admin.enable_two_factor!
    log_in
    get audit_logs_path
    assert_redirected_to new_two_factor_challenge_path
    post two_factor_challenge_path, params: { otp_code: ROTP::TOTP.new(@admin.otp_secret).now }
    assert_redirected_to "/audit_logs"
  end

  test "the setup page says 'required' once, not twice" do
    log_in
    post vehicles_path, params: { vehicle: { name: "Van" } }
    follow_redirect!
    assert_match "before adding your own data", response.body
    assert_no_match "is required for admin", response.body

    get two_factor_setup_path # a plain visit, no alert: the page explains itself
    assert_match "is required for admin", response.body
  end
end
