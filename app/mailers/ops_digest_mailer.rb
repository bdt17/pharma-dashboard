# The Monday operator email: the week's funnel numbers and anything waiting
# on the operator (see Ops::WeeklyDigest), so /ops doesn't have to be
# checked by hand. Same recipient rule as CallRequestMailer.
class OpsDigestMailer < ApplicationMailer
  def weekly(digest = Ops::WeeklyDigest.new)
    @digest = digest
    to = ENV["LEADS_EMAIL"].presence || self.class.default[:from]

    mail(to: to, subject: "Pharma Transport weekly — #{digest.headline}")
  end
end
