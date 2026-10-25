# Tells the operator a new subscriber qualified for the free White-Glove
# Setup (see DeadlineOffer) so the setup call gets booked while the trial
# is fresh. Same recipient rule as CallRequestMailer.
class FreeSetupMailer < ApplicationMailer
  def owed(organization)
    @organization = organization
    @users = organization.users.order(:created_at)
    to = ENV["LEADS_EMAIL"].presence || self.class.default[:from]

    mail(
      to: to,
      reply_to: @users.first&.email,
      subject: "Free setup owed — #{organization.name} just subscribed"
    )
  end
end
