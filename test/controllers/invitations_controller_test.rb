require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @invitation = @organization.invitations.create!(email: "new.driver@example.com", role: "driver", invited_by: @admin)
    @token = @invitation.token
  end

  def accept_params(**overrides)
    { user: { name: "Dana Driver", password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }.merge(overrides) }
  end

  test "shows the join form for a valid link" do
    get invitation_url(token: @token)
    assert_response :success
    assert_match "Join Acme Pharma", response.body
    assert_match "new.driver@example.com", response.body
  end

  test "an unknown, revoked, or expired link gets the same not-valid page" do
    get invitation_url(token: "nope")
    assert_response :not_found
    assert_match "isn't valid", response.body

    @invitation.revoke!
    get invitation_url(token: @token)
    assert_response :not_found
    assert_match "isn't valid", response.body
    assert_no_match "new.driver@example.com", response.body
  end

  test "accepting creates the member, signs them in, and burns the link" do
    assert_difference -> { @organization.users.count }, 1 do
      post invitation_url(token: @token), params: accept_params
    end
    assert_redirected_to dashboard_path

    member = User.find_by(email: "new.driver@example.com")
    assert_equal "driver", member.role
    assert_equal "Dana Driver", member.name
    assert AuditLog.exists?(event: "team_invitation_accepted", user: member)

    follow_redirect!
    assert_response :success

    sign_out member
    post invitation_url(token: @token), params: accept_params
    assert_response :not_found
  end

  test "the submitted role or email can't override the invitation" do
    post invitation_url(token: @token), params: accept_params(role: "admin", email: "evil@example.com")
    member = @organization.users.order(:created_at).last
    assert_equal "new.driver@example.com", member.email
    assert_equal "driver", member.role
  end

  test "a bad password re-renders without using up the invitation" do
    post invitation_url(token: @token), params: accept_params(password: "short", password_confirmation: "short")
    assert_response :unprocessable_content
    assert_predicate @invitation.reload, :pending?
  end

  test "a pharmacist invitee is sent to two-factor setup" do
    invitation = @organization.invitations.create!(email: "rph@example.com", role: "pharmacist", invited_by: @admin)
    post invitation_url(token: invitation.token), params: accept_params
    member = User.find_by(email: "rph@example.com")
    assert member.two_factor_required?
  end

  test "a signed-in user is asked to sign out instead of accepting" do
    sign_in @admin
    get invitation_url(token: @token)
    assert_match "Sign out first", response.body

    assert_no_difference -> { User.count } do
      post invitation_url(token: @token), params: accept_params
    end
  end
end
