require "application_system_test_case"

# The signup -> dashboard (explore, unconfirmed) -> two-factor enrolment
# path. This is exactly the flow that broke repeatedly (full_bleed layout,
# QR rendering, half-enrolled 2FA, bcrypt) with every individual piece
# green in the controller/model suites.
class AuthenticationFlowTest < ApplicationSystemTestCase
  test "a new admin signs up, explores, enrols two-factor, and reaches the dashboard" do
    email = "founder-#{SecureRandom.hex(4)}@example.com"

    visit new_user_registration_path
    fill_in "Pharmacy name", with: "Northwind Pharmacy"
    fill_in "Email", with: email
    fill_in "Password", with: "correct horse battery"
    fill_in "Confirm password", with: "correct horse battery"
    check "user_terms_accepted"
    click_on "Create account"

    # Signup lands straight in the dashboard, unconfirmed and exploring
    # (24-hour email grace; two-factor before real data). Waiting on this
    # Capybara matcher (which retries) also covers the race where the signup
    # POST hasn't hit the database before User.find_by! runs.
    assert_selector "h1", text: "Dashboard"
    assert_text "Confirm your email."
    assert_text "You’re exploring."
    user = User.find_by!(email: email)
    assert_not user.confirmed?

    click_on "Set up two-factor"
    assert_selector "h1", text: "Set up two-factor authentication"
    # visible: :all skips Capybara's per-candidate displayed? RPC, which
    # intermittently threw "Node with given id does not belong to the
    # document" here -- the bare selector matched the layout mark as well
    # as the QR, and a match could detach mid-check. Presence is all this
    # asserts; the manual-key <code> check on the next line (text-filtered,
    # so it retries cleanly) confirms the page actually rendered.
    assert_selector "svg", visible: :all           # the QR renders
    assert_selector "code", text: user.reload.otp_secret

    fill_in "6-digit code", with: ROTP::TOTP.new(user.otp_secret).now
    click_on "Verify and continue"

    # Backup codes shown exactly once.
    assert_selector "h1", text: "Backup codes"
    assert_selector "li", minimum: 10, visible: :all
    click_on "I've saved these"

    assert_selector "h1", text: "Dashboard"
    assert_text "Northwind Pharmacy"
    assert_no_text "You’re exploring."
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
