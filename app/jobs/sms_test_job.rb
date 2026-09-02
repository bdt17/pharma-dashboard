# Sends a one-off "this is a test" SMS to a single alert recipient, so an
# operator can confirm Twilio is wired without forcing a real excursion.
# Enqueued from AlertSettingsController#test.
class SmsTestJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(alert_recipient_id)
    recipient = AlertRecipient.find_by(id: alert_recipient_id)
    return unless recipient

    SmsSender.deliver(
      to: recipient.phone,
      body: "Pharma Transport: test alert for #{recipient.organization.name}. " \
            "If you got this, temperature-excursion texts are working."
    )
  rescue SmsSender::NotConfigured => e
    Rails.logger.warn("[SmsTestJob] skipped: #{e.message}")
  end
end
