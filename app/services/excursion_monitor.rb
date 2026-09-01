# Turns a stream of Telemetry readings into ExcursionEvents and hands each
# state transition to ExcursionNotifier -- once when a shipment goes out
# of the 2-8°C range, once when it comes back. Called from
# Telemetry#after_create_commit.
#
# Deduplication is the whole point: a truck parked at 15°C pings every
# few seconds, and we send exactly one "excursion started" notification,
# not one per ping. The open ExcursionEvent is that piece of state --
# while one is open for a batch, further out-of-range readings only
# extend it.
class ExcursionMonitor
  def self.evaluate(telemetry)
    new(telemetry).evaluate
  end

  def initialize(telemetry)
    @telemetry = telemetry
    @batch = telemetry.batch
  end

  def evaluate
    return unless @batch && @telemetry.temp

    if in_range?(@telemetry.temp)
      close_open_event
    else
      open_or_extend_event
    end
  end

  private

  attr_reader :telemetry, :batch

  def in_range?(temp)
    Batch::COMPLIANT_RANGE.cover?(temp)
  end

  def reading_time
    telemetry.recorded_at || Time.current
  end

  def open_or_extend_event(attempt: 1)
    if (event = ExcursionEvent.ongoing.find_by(batch_id: batch.id))
      event.update!(
        peak_temp: farther_from_range(event.peak_temp, telemetry.temp),
        readings_count: event.readings_count + 1
      )
      return
    end

    event = ExcursionEvent.create!(
      batch: batch,
      vehicle: telemetry.vehicle,
      started_at: reading_time,
      trigger_temp: telemetry.temp,
      peak_temp: telemetry.temp,
      readings_count: 1,
      alerted_at: Time.current
    )
    ExcursionNotifier.alert(event)
  rescue ActiveRecord::RecordNotUnique
    # A concurrent reading opened the event first -- treat this one as an
    # extension of that event instead. Bounded so a genuinely stuck state
    # can't spin here forever.
    raise if attempt >= 3

    open_or_extend_event(attempt: attempt + 1)
  end

  def close_open_event
    event = ExcursionEvent.ongoing.find_by(batch_id: batch.id)
    return unless event

    event.update!(ended_at: reading_time)
    ExcursionNotifier.resolved(event)
  end

  # Keep whichever temperature is the more severe excursion -- farthest
  # from the midpoint of the compliant range.
  def farther_from_range(a, b)
    midpoint = (Batch::COMPLIANT_RANGE.begin + Batch::COMPLIANT_RANGE.end) / 2.0
    (a - midpoint).abs >= (b - midpoint).abs ? a : b
  end
end
