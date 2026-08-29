# Notifies the team that someone asked to be called. Goes to LEADS_EMAIL
# if set, otherwise the MAILER_SENDER address (ApplicationMailer default).
class CallRequestMailer < ApplicationMailer
  def notify(call_request)
    @call_request = call_request
    to = ENV["LEADS_EMAIL"].presence || self.class.default[:from]

    mail(
      to: to,
      reply_to: call_request.email,
      subject: "Call request (#{call_request.topic_label}) — #{call_request.pharmacy_name.presence || call_request.name}"
    )
  end
end
