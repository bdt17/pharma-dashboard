# Sends one SMS for one excursion to one number. Enqueued per active
# recipient by ExcursionNotifier when the organization is on a plan that
# includes SMS alerts.
#
# A missing Twilio config or a since-deleted event is not an error worth
# retrying -- log and move on. A Twilio-side delivery failure is allowed
# to raise so ActiveJob retries it.
class SmsExcursionAlertJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(excursion_event_id, phone)
    event = ExcursionEvent.find_by(id: excursion_event_id)
    return unless event

    batch = event.batch
    SmsSender.deliver(to: phone, body: message_for(event, batch))
  rescue SmsSender::NotConfigured => e
    Rails.logger.warn("[SmsExcursionAlertJob] skipped: #{e.message}")
  end

  private

  def message_for(event, batch)
    direction = event.direction == "warm" ? "above" : "below"
    vehicle = event.vehicle&.name

    [
      "Pharma Transport alert:",
      "#{batch.lot_number} is #{direction} 2-8°C",
      "(#{event.trigger_temp.round(1)}°C#{" on #{vehicle}" if vehicle}).",
      "Started #{event.started_at.strftime("%H:%M %Z")}."
    ].join(" ")
  end
end
