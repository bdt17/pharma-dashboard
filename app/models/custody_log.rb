class CustodyLog < ApplicationRecord
  belongs_to :batch

  ACTION_TYPES = %w[pickup in_transit handoff delivered exception].freeze

  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :handler_name, presence: true
  validates :location, presence: true

  before_validation :set_timestamp, on: :create

  # Chain-of-custody records are meant to be an immutable log of what
  # actually happened -- there is deliberately no update/destroy path here.
  # A correction is a new CustodyLog entry (e.g. action_type: "exception"),
  # not an edit of history.

  private

  def set_timestamp
    self.timestamp ||= Time.current
  end
end
