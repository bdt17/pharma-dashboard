# One temperature-excursion interval for a batch -- see the migration.
# Opened, extended, and closed exclusively by ExcursionMonitor as
# Telemetry readings come in; never edited by hand.
class ExcursionEvent < ApplicationRecord
  belongs_to :batch
  belongs_to :vehicle, optional: true

  validates :started_at, :trigger_temp, :peak_temp, presence: true

  scope :ongoing, -> { where(ended_at: nil) }
  scope :resolved, -> { where.not(ended_at: nil) }
  scope :recent_first, -> { order(started_at: :desc) }

  def ongoing?
    ended_at.nil?
  end

  # Seconds the excursion has lasted so far (or lasted, once closed).
  def duration
    (ended_at || Time.current) - started_at
  end

  # Which side of the 2-8°C range the shipment went: too warm is the
  # common cold-chain failure, too cold (frozen) matters for some drugs.
  def direction
    trigger_temp > Batch::COMPLIANT_RANGE.end ? "warm" : "cold"
  end
end
