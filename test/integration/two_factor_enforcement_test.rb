require "test_helper"

# Exercises the real gate (ApplicationController#enforce_two_factor) by driving
# an actual password login rather than Devise::Test's sign_in helper.
class TwoFactorEnforcementTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  def create_user(role:)
    User.create!(
      email: "#{role}@example.com", password: "password123!",
      organization: @organization, role: role
    )
  end

  def log_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123!" } }
  end

  test "an un-enrolled opt-in user is not challenged and reaches the dashboard" do
    log_in create_user(role: "dispatcher")
    get dashboard_path
    assert_response :success
  end

  test "an un-enrolled admin of an account with real data is forced into two-factor setup" do
    admin = create_user(role: "admin")
    vehicle = Vehicle.create!(name: "Van", organization: @organization)
    Batch.create!(lot_number: "LOT-1", vehicle: vehicle, organization: @organization)
    log_in admin
    get dashboard_path
    assert_redirected_to two_factor_setup_path
  end

  test "an un-enrolled admin of an empty account may explore and try sample data" do
    log_in create_user(role: "admin")
    get dashboard_path
    assert_response :success
    assert_match "You&rsquo;re exploring.", response.body

    post sample_data_path
    assert_redirected_to dashboard_path
    assert @organization.reload.sample_data?

    get compliance_path
    assert_response :success
  end

  test "exploring stops at the first real write, account change, or invite" do
    log_in create_user(role: "admin")

    assert_no_difference -> { Vehicle.count } do
      post vehicles_path, params: { vehicle: { name: "Our van" } }
    end
    assert_redirected_to two_factor_setup_path
    assert_match "before adding your own data", flash[:alert]

    post team_invitations_path, params: { invitation: { email: "d@example.com", role: "driver" } }
    assert_redirected_to two_factor_setup_path

    get edit_user_registration_path
    assert_redirected_to two_factor_setup_path
  end

  test "sample data alone doesn't end exploring, but a teammate does" do
    admin = create_user(role: "admin")
    SampleData.load!(@organization, user: admin)
    assert admin.reload.two_factor_grace?

    create_user(role: "driver")
    assert_not admin.reload.two_factor_grace?
  end

  test "an un-enrolled pharmacist is forced into two-factor setup" do
    log_in create_user(role: "pharmacist")
    get dashboard_path
    assert_redirected_to two_factor_setup_path
  end

  test "an enrolled user must pass the challenge before reaching an authenticated page" do
    user = create_user(role: "dispatcher")
    user.generate_otp_secret!
    user.enable_two_factor!

    log_in user
    get dashboard_path
    assert_redirected_to new_two_factor_challenge_path

    post two_factor_challenge_path, params: { otp_code: ROTP::TOTP.new(user.otp_secret).now }
    get dashboard_path
    assert_response :success
  end

  test "signing in again re-triggers the challenge in the same browser session" do
    user = create_user(role: "dispatcher")
    user.generate_otp_secret!
    user.enable_two_factor!
    totp = ROTP::TOTP.new(user.otp_secret)

    log_in user
    post two_factor_challenge_path, params: { otp_code: totp.now }
    get dashboard_path
    assert_response :success

    delete destroy_user_session_path
    log_in user
    get dashboard_path
    assert_redirected_to new_two_factor_challenge_path
  end

  test "a JSON API request before the second factor gets a 401, not a redirect or data" do
    user = create_user(role: "admin") # required role, not enrolled
    Vehicle.create!(name: "Truck 1", organization: @organization)

    log_in user
    get "/api/v1/vehicles", headers: { "Accept" => "application/json" }

    assert_response :unauthorized
    assert_equal "application/json", response.media_type
  end

  test "the JSON API still works for an opt-in user who hasn't enrolled" do
    log_in create_user(role: "dispatcher")
    get "/api/v1/vehicles", headers: { "Accept" => "application/json" }

    assert_response :success
  end

  test "an Accept: application/json header doesn't skip the gate on an HTML route" do
    user = create_user(role: "dispatcher")
    user.generate_otp_secret!
    user.enable_two_factor!

    log_in user
    assert_no_difference -> { @organization.vehicles.count } do
      post vehicles_path, params: { vehicle: { name: "Sneaky" } }, headers: { "Accept" => "application/json" }
    end
    assert_response :unauthorized
  end

  test "account settings (Devise registrations) are behind the gate" do
    user = create_user(role: "dispatcher")
    user.generate_otp_secret!
    user.enable_two_factor!

    log_in user
    get edit_user_registration_path
    assert_redirected_to new_two_factor_challenge_path

    assert_no_difference -> { User.count } do
      delete user_registration_path
    end
  end

  test "sign-out still works before the second factor" do
    user = create_user(role: "dispatcher")
    user.generate_otp_secret!
    user.enable_two_factor!

    log_in user
    delete destroy_user_session_path
    get dashboard_path
    assert_redirected_to new_user_session_path
  end
end
