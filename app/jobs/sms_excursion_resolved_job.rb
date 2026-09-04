# Sends one "all clear" SMS for one excursion to one number. Sibling of
# SmsExcursionAlertJob, kept as its own job (not a second message inside
# that one) for the same reason SmsTestJob is separate -- a distinct
# purpose gets a distinct, obviously-named job rather than a branch
# inside an existing one.
#
# Opt-in only -- see Organization#all_clear_sms_enabled? and
# ExcursionNotifier.resolved, which is what enqueues this. Off by
# default: an unwanted "all clear" text is a smaller problem than an
# unwanted alert, but it's still an SMS nobody asked for.
class SmsExcursionResolvedJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  def perform(excursion_event_id, phone)
    event = ExcursionEvent.find_by(id: excursion_event_id)
    return unless event

    batch = event.batch
    SmsSender.deliver(to: phone, body: message_for(event, batch))
  rescue SmsSender::NotConfigured => e
    Rails.logger.warn("[SmsExcursionResolvedJob] skipped: #{e.message}")
  end

  private

  def message_for(event, batch)
    vehicle = event.vehicle&.name

    [
      "Pharma Transport: all clear.",
      "#{batch.lot_number} is back in range 2-8°C#{" on #{vehicle}" if vehicle}.",
      "Resolved #{event.ended_at&.strftime("%H:%M %Z")}."
    ].join(" ")
  end
end
