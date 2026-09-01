# Fans a temperature-excursion event out to every channel the
# organization has: email (always, to admins + pharmacists) and SMS
# (opt-in, Pro/Compliance tiers, one message per configured recipient).
#
# ExcursionMonitor calls this instead of talking to the mailer directly,
# so adding a channel later (voice, webhook, Slack) is a change here and
# nowhere else.
class ExcursionNotifier
  def self.alert(event)
    ExcursionMailer.alert(event).deliver_later
    enqueue_sms(event)
  end

  def self.resolved(event)
    # Email only: the "resolved" message is reassurance, not something
    # worth a text (and an SMS bill) at 3am.
    ExcursionMailer.resolved(event).deliver_later
  end

  def self.enqueue_sms(event)
    organization = event.batch.organization
    return unless organization.alert_sms_available?

    organization.alert_recipients.active.find_each do |recipient|
      SmsExcursionAlertJob.perform_later(event.id, recipient.phone)
    end
  end
  private_class_method :enqueue_sms
end
