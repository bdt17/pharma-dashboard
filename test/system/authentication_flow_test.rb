require "application_system_test_case"

# The signup -> confirm -> sign in -> mandatory 2FA enrolment -> dashboard
# path. This is exactly the flow that broke repeatedly (full_bleed layout,
# QR rendering, half-enrolled 2FA, bcrypt) with every individual piece
# green in the controller/model suites.
class AuthenticationFlowTest < ApplicationSystemTestCase
  test "a new admin signs up, confirms, enrols two-factor, and reaches the dashboard" do
    email = "founder-#{SecureRandom.hex(4)}@example.com"

    visit new_user_registration_path
    fill_in "Organization name", with: "Northwind Pharmacy"
    fill_in "Email", with: email
    fill_in "Password", with: "correct horse battery"
    fill_in "Confirm password", with: "correct horse battery"
    check "user_terms_accepted"
    click_on "Create organization"

    # click_on returns as soon as the click is dispatched -- the signup
    # POST may not have hit the database yet. Wait on the post-signup flash
    # (a Capybara matcher, which retries) before querying for the user
    # directly with User.find_by!, which does not. This race is what made
    # the test flake in CI.
    assert_text "confirmation link has been sent"

    # Confirmable is on for the signup path; a real inbox isn't available in
    # a system test, so confirm directly -- the point here is the 2FA gate.
    user = User.find_by!(email: email)
    assert_not user.confirmed?
    user.confirm

    visit new_user_session_path
    fill_in "Email", with: email
    fill_in "Password", with: "correct horse battery"
    click_on "Sign in"

    # Admins are forced into enrolment before any authenticated page.
    assert_selector "h1", text: "Set up two-factor authentication"
    assert_selector "svg"                        # the QR renders
    assert_selector "code", text: user.reload.otp_secret

    fill_in "6-digit code", with: ROTP::TOTP.new(user.otp_secret).now
    click_on "Verify and continue"

    # Backup codes shown exactly once.
    assert_selector "h1", text: "Backup codes"
    assert_selector "li", minimum: 10
    click_on "I've saved these"

    assert_selector "h1", text: "Dashboard"
    assert_text "Northwind Pharmacy"
    assert user.reload.otp_enabled?
    assert_equal 10, user.backup_codes_remaining
  end

  test "an enrolled admin is challenged for a code on a fresh sign-in" do
    org = Organization.create!(name: "Meridian Pharmacy")
    user = User.create!(email: "e-#{SecureRandom.hex(4)}@example.com", password: "correct horse battery",
                        organization: org, role: "admin")
    # Enrol without consuming a timestep, so a "now" code isn't blocked by
    # the replay guard on the challenge screen.
    user.generate_otp_secret!
    user.update!(otp_enabled: true, otp_enabled_at: Time.current)
    user.generate_backup_codes!

    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "correct horse battery"
    click_on "Sign in"

    assert_selector "h1", text: "Enter your authentication code"
    fill_in "Authentication or backup code", with: ROTP::TOTP.new(user.otp_secret).now
    click_on "Verify"

    assert_selector "h1", text: "Dashboard"
  end
end
