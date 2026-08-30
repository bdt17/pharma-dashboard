# Just the /ops "send myself a test email" button -- exercises the real
# ActionMailer delivery path (SMTP settings, sender address) so an
# operator can confirm outbound email works without waiting for a signup.
class OpsMailer < ApplicationMailer
  def test_message(to:)
    mail(to: to, subject: "Pharma Transport ops test") do |format|
      format.text { render plain: "Sent from /ops at #{Time.current.iso8601}.\n\nIf you're reading this, outbound email works." }
    end
  end
end
