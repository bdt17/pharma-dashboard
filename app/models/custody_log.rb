class CustodyLog < ApplicationRecord
  belongs_to :batch

  ACTION_TYPES = %w[pickup in_transit handoff delivered exception].freeze

  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :handler_name, presence: true
  validates :location, presence: true
  validate :signature_required_for_delivery

  before_validation :set_timestamp, on: :create

  # Chain-of-custody records are meant to be an immutable log of what
  # actually happened -- there is deliberately no update/destroy path here.
  # A correction is a new CustodyLog entry (e.g. action_type: "exception"),
  # not an edit of history.

  # True once a real signature has been captured -- checked from both the
  # validation below and PdfChainOfCustodyGenerator, so "what counts as
  # present" is defined in exactly one place.
  def signed?
    signature_data.present? && signature_data["image"].present? && signature_data["signer_name"].present?
  end

  private

  def set_timestamp
    self.timestamp ||= Time.current
  end

  # Proof of delivery is the point a signature actually matters -- other
  # action types (pickup, in_transit, handoff, exception) don't require one.
  def signature_required_for_delivery
    return unless action_type == "delivered"
    return if signed?

    errors.add(:signature_data, "must include a signature and signer name to confirm delivery")
  end
end
