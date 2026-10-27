# The organization's people: who's on the team, who's been invited, and
# (for an admin) inviting, changing roles, and deactivating. Everyone in
# the organization can see the list; only an admin can change it.
#
# Members are deactivated, never deleted -- see User#deactivated?. The
# organization must always keep at least one active admin, or nobody could
# manage billing or the team again without the operator stepping in.
class TeamController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin, except: :index
  before_action :set_member, only: %i[update_member deactivate reactivate]
  before_action :set_invitation, only: %i[revoke resend]

  def index
    load_team
    @invitation = Invitation.new(role: "driver")
  end

  def invite
    @invitation = current_organization.invitations.build(
      email: params.dig(:invitation, :email),
      role: params.dig(:invitation, :role),
      invited_by: current_user
    )

    if @invitation.save
      InvitationMailer.invite(@invitation, @invitation.token).deliver_later
      audit!("team_member_invited", email: @invitation.email, role: @invitation.role)
      redirect_to team_path, notice: "Invitation sent to #{@invitation.email}. The link expires in #{Invitation::EXPIRES_IN.inspect}."
    else
      load_team
      render :index, status: :unprocessable_content
    end
  end

  def resend
    @invitation.regenerate_token!
    InvitationMailer.invite(@invitation, @invitation.token).deliver_later
    audit!("team_invitation_resent", email: @invitation.email)
    redirect_to team_path, notice: "Sent a new link to #{@invitation.email}. The old one no longer works."
  end

  def revoke
    @invitation.revoke!
    audit!("team_invitation_revoked", email: @invitation.email)
    redirect_to team_path, notice: "Revoked the invitation to #{@invitation.email}."
  end

  def update_member
    role = params.dig(:user, :role).to_s
    unless User.roles.key?(role)
      redirect_to team_path, alert: "Pick a valid role."
      return
    end
    if role != "admin" && last_active_admin?(@member)
      redirect_to team_path, alert: "#{label(@member)} is the only admin. Make someone else an admin first."
      return
    end

    previous = @member.role
    @member.update!(role: role)
    audit!("team_member_role_changed", email: @member.email, from: previous, to: role)
    redirect_to team_path, notice: "#{label(@member)} is now #{role.start_with?("a") ? "an" : "a"} #{role}."
  end

  def deactivate
    if @member == current_user
      redirect_to team_path, alert: "You can't deactivate your own account."
      return
    end
    if last_active_admin?(@member)
      redirect_to team_path, alert: "#{label(@member)} is the only admin. Make someone else an admin first."
      return
    end

    @member.update!(deactivated_at: Time.current)
    audit!("team_member_deactivated", email: @member.email)
    redirect_to team_path, notice: "Deactivated #{label(@member)}. They're signed out and can't sign in; their records stay."
  end

  def reactivate
    @member.update!(deactivated_at: nil)
    audit!("team_member_reactivated", email: @member.email)
    redirect_to team_path, notice: "Reactivated #{label(@member)}."
  end

  private

  def load_team
    @members = current_organization.users.order(Arel.sql("deactivated_at IS NOT NULL"), :created_at)
    @invitations = current_organization.invitations.pending.includes(:invited_by).order(:created_at)
  end

  def require_admin
    return if current_user.admin?

    redirect_to team_path, alert: "Only an organization admin can manage the team."
  end

  def set_member
    @member = current_organization.users.find(params[:id])
  end

  def set_invitation
    @invitation = current_organization.invitations.pending.find(params[:id])
  end

  def last_active_admin?(member)
    member.admin? && !member.deactivated? &&
      !current_organization.users.active.admin.where.not(id: member.id).exists?
  end

  def label(member)
    member.name.presence || member.email
  end

  def audit!(event, data)
    AuditLog.record!(event: event, user: current_user, ip_address: request.remote_ip, data: data)
  end
end
