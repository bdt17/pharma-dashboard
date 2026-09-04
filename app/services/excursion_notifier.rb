# Fans a temperature-excursion event out to every channel the
# organization has: email (always, to admins + pharmacists), SMS (opt-in,
# Pro/Compliance tiers, one message per configured recipient), and
# outbound webhooks (Compliance tier).
#
# ExcursionMonitor calls this instead of talking to the mailer directly,
# so adding a channel is a change here and nowhere else.
class ExcursionNotifier
  def self.alert(event)
    ExcursionMailer.alert(event).deliver_later
    enqueue_sms(event)
    publish_webhook(event, "excursion.started")
  end

  def self.resolved(event)
    # Email only for the human channels: the "resolved" message is
    # reassurance, not something worth a text (and an SMS bill) at 3am.
    ExcursionMailer.resolved(event).deliver_later
    publish_webhook(event, "excursion.resolved")
  end

  def self.enqueue_sms(event)
    organization = event.batch.organization
    return unless organization.alert_sms_available?

    # Quiet hours only ever delays the text, never drops it -- and only
    # the text. Email and the webhook are both immediate regardless (see
    # .alert above), by design: SMS is the one channel someone can be
    # woken up by, the other two are read whenever they're read.
    send_at = organization.sms_quiet_hours_active? ? organization.sms_quiet_hours_end_at : nil

    organization.alert_recipients.active.find_each do |recipient|
      if send_at
        SmsExcursionAlertJob.set(wait_until: send_at).perform_later(event.id, recipient.phone)
      else
        SmsExcursionAlertJob.perform_later(event.id, recipient.phone)
      end
    end
  end
  private_class_method :enqueue_sms

  def self.publish_webhook(event, name)
    batch = event.batch
    WebhookDispatcher.publish(
      organization: batch.organization,
      event: name,
      data: {
        lot_number: batch.lot_number,
        vehicle: event.vehicle&.name,
        direction: event.direction,
        trigger_temp: event.trigger_temp,
        peak_temp: event.peak_temp,
        readings_count: event.readings_count,
        started_at: event.started_at&.iso8601,
        ended_at: event.ended_at&.iso8601
      }
    )
  end
  private_class_method :publish_webhook
end
