require "test_helper"

class TeamControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @dispatcher = User.create!(email: "dispatch@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @other_org = Organization.create!(name: "Other Rx")
    @outsider = User.create!(email: "outsider@example.com", password: "password123!", organization: @other_org, role: "driver")
  end

  test "requires authentication" do
    get team_url
    assert_redirected_to new_user_session_url
  end

  test "any member sees their own organization's team, not another's" do
    sign_in @dispatcher
    get team_url
    assert_response :success
    assert_match "admin@example.com", response.body
    assert_no_match "outsider@example.com", response.body
    assert_select "form[action=?]", team_invitations_path, count: 0
  end

  test "an admin sees the invite form" do
    sign_in @admin
    get team_url
    assert_select "form[action=?]", team_invitations_path
  end

  test "an admin invites someone and the email goes out with a working link" do
    sign_in @admin

    assert_difference -> { @organization.invitations.count }, 1 do
      assert_enqueued_emails 1 do
        post team_invitations_url, params: { invitation: { email: "Driver.One@example.com", role: "driver" } }
      end
    end
    assert_redirected_to team_path

    invitation = @organization.invitations.last
    assert_equal "driver.one@example.com", invitation.email
    assert_equal @admin, invitation.invited_by
    assert AuditLog.exists?(event: "team_member_invited", user: @admin)

    perform_enqueued_jobs
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "driver.one@example.com" ], mail.to
    token = mail.text_part.body.to_s[%r{/invitations/([\w-]+)}, 1]
    assert_equal invitation, Invitation.find_pending_by_token(token)
  end

  test "an invalid invite re-renders with the error and sends nothing" do
    sign_in @admin
    assert_no_enqueued_emails do
      post team_invitations_url, params: { invitation: { email: "outsider@example.com", role: "driver" } }
    end
    assert_response :unprocessable_content
    assert_match "already has a Pharma Transport account", response.body
  end

  test "a non-admin can't invite, change roles, or deactivate" do
    sign_in @dispatcher

    assert_no_difference -> { Invitation.count } do
      post team_invitations_url, params: { invitation: { email: "x@example.com", role: "admin" } }
    end
    assert_redirected_to team_path

    patch team_member_url(@dispatcher), params: { user: { role: "admin" } }
    assert_equal "dispatcher", @dispatcher.reload.role

    post deactivate_team_member_url(@admin)
    assert_not @admin.reload.deactivated?
  end

  test "an admin can't touch another organization's members or invitations" do
    other_admin = User.create!(email: "oadmin@example.com", password: "password123!", organization: @other_org, role: "admin")
    foreign = @other_org.invitations.create!(email: "f@example.com", role: "driver", invited_by: other_admin)
    # Re-signed in before each request: Devise's test sign_in writes the
    # session during the request, and a 404 response never saves it.
    sign_in @admin
    post deactivate_team_member_url(@outsider)
    assert_response :not_found
    sign_in @admin
    patch team_member_url(@outsider), params: { user: { role: "admin" } }
    assert_response :not_found
    sign_in @admin
    delete team_invitation_url(foreign)
    assert_response :not_found
    assert_not @outsider.reload.deactivated?
    assert_predicate foreign.reload, :pending?
  end

  test "an admin changes a member's role" do
    sign_in @admin
    patch team_member_url(@dispatcher), params: { user: { role: "pharmacist" } }
    assert_redirected_to team_path
    assert_equal "pharmacist", @dispatcher.reload.role
    assert AuditLog.exists?(event: "team_member_role_changed")
  end

  test "rejects an unknown role" do
    sign_in @admin
    patch team_member_url(@dispatcher), params: { user: { role: "owner" } }
    assert_equal "dispatcher", @dispatcher.reload.role
  end

  test "the last active admin can't be demoted, and can't deactivate themselves" do
    sign_in @admin
    patch team_member_url(@admin), params: { user: { role: "driver" } }
    assert_equal "admin", @admin.reload.role
    assert_match "only admin", flash[:alert]

    post deactivate_team_member_url(@admin)
    assert_not @admin.reload.deactivated?
  end

  test "an admin can step down once there's another admin" do
    @dispatcher.update!(role: "admin")
    sign_in @admin
    patch team_member_url(@admin), params: { user: { role: "dispatcher" } }
    assert_equal "dispatcher", @admin.reload.role
  end

  test "deactivating signs the member out on their next request and blocks sign-in; reactivating restores it" do
    sign_in @admin
    post deactivate_team_member_url(@dispatcher)
    assert_predicate @dispatcher.reload, :deactivated?
    assert AuditLog.exists?(event: "team_member_deactivated")

    sign_out @admin
    sign_in @dispatcher
    get dashboard_url
    assert_redirected_to new_user_session_url

    post user_session_url, params: { user: { email: "dispatch@example.com", password: "password123!" } }
    assert_match "deactivated", flash[:alert]

    sign_in @admin
    post reactivate_team_member_url(@dispatcher)
    assert_not @dispatcher.reload.deactivated?
  end

  test "resend replaces the link; revoke kills it" do
    sign_in @admin
    invitation = @organization.invitations.create!(email: "pending@example.com", role: "driver", invited_by: @admin)
    old_token = invitation.token

    assert_enqueued_emails 1 do
      post resend_team_invitation_url(invitation)
    end
    assert_nil Invitation.find_pending_by_token(old_token)

    delete team_invitation_url(invitation)
    assert_not invitation.reload.pending?
    get team_url
    assert_select "td", text: "pending@example.com", count: 0
  end
end
