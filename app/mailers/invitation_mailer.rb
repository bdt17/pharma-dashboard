# The invite link a new team member uses to join an organization (see
# Invitation). The raw token is passed in rather than read off the record,
# because only its digest is stored.
class InvitationMailer < ApplicationMailer
  def invite(invitation, token)
    @invitation = invitation
    @inviter = invitation.invited_by
    @url = invitation_url(token: token)

    mail(
      to: invitation.email,
      reply_to: @inviter.email,
      subject: "#{inviter_name} invited you to #{invitation.organization.name} on Pharma Transport"
    )
  end

  private

  def inviter_name
    @inviter.name.presence || @inviter.email
  end
end
