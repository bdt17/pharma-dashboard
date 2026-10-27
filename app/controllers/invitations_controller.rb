# Accepting a team invitation (see Invitation, TeamController). Public: the
# emailed token is the credential, and an unknown, used, revoked, or
# expired token all get the same "no longer valid" page, so the response
# says nothing about which.
#
# Signs the new member in straight away. Roles that require two-factor
# (admin, pharmacist) are sent to enrollment by
# ApplicationController#enforce_two_factor on their next request, same as a
# fresh signup.
class InvitationsController < ApplicationController
  before_action :set_invitation

  def show
    @user = User.new(email: @invitation.email) if @invitation
    render_invalid unless @invitation
  end

  def accept
    return render_invalid unless @invitation
    return redirect_to(invitation_path(token: params[:token])) if user_signed_in?

    @user = @invitation.accept!(
      name: params.dig(:user, :name),
      password: params.dig(:user, :password),
      password_confirmation: params.dig(:user, :password_confirmation),
      terms_accepted: params.dig(:user, :terms_accepted)
    )

    if @user.persisted?
      AuditLog.record!(event: "team_invitation_accepted", user: @user, ip_address: request.remote_ip,
                       data: { email: @user.email, role: @user.role, invited_by: @invitation.invited_by.email })
      sign_in(@user)
      redirect_to dashboard_path, notice: "Welcome to #{@invitation.organization.name}."
    else
      @user.password = @user.password_confirmation = nil
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_pending_by_token(params[:token])
  end

  def render_invalid
    render :invalid, status: :not_found
  end
end
