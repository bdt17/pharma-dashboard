require "test_helper"

class OtherSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "dispatch@example.com", password: "password123!", organization: @organization, role: "dispatcher")
  end

  def log_in(session, remember: false)
    session.post user_session_url, params: { user: { email: @user.email, password: "password123!", remember_me: remember ? "1" : "0" } }
    session.get dashboard_url
    session.assert_response :success
  end

  test "requires authentication" do
    delete other_sessions_url
    assert_redirected_to new_user_session_url
  end

  test "signs out every other browser, including a remembered one, and keeps this one" do
    here = open_session
    phone = open_session
    log_in(here)
    log_in(phone, remember: true)

    here.delete other_sessions_url
    here.assert_redirected_to two_factor_setup_url
    assert AuditLog.exists?(event: "signed_out_other_sessions", user: @user)

    phone.get dashboard_url
    phone.assert_redirected_to new_user_session_url

    here.get dashboard_url
    here.assert_response :success
  end

  test "an admin keeps their passed second factor" do
    admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    admin.update!(otp_secret: ROTP::Base32.random, otp_enabled: true, otp_enabled_at: Time.current)

    sign_in admin
    delete other_sessions_url
    get dashboard_url

    assert_response :success
  end

  test "the Security page offers it" do
    sign_in @user
    get two_factor_setup_url

    assert_select "form[action=?]", other_sessions_path
  end
end
