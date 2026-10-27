class CustodyLog < ApplicationRecord
  belongs_to :batch

  ACTION_TYPES = %w[pickup in_transit handoff delivered exception].freeze

  # What the signature pad submits: a PNG data URL (see
  # signature_pad_controller.js). Anything else is rejected at create time,
  # because custody logs are immutable -- one unreadable image saved here
  # would break every chain-of-custody PDF and compliance packet for the
  # batch for good. The size and dimension caps keep a small, highly
  # compressed "image bomb" from exhausting memory when Prawn inflates it.
  SIGNATURE_DATA_URL = %r{\Adata:image/png;base64,([A-Za-z0-9+/]+={0,2})\z}
  MAX_SIGNATURE_LENGTH = 400_000
  MAX_SIGNATURE_DIMENSION = 4000
  PNG_MAGIC = "\x89PNG\r\n\x1A\n".b.freeze

  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :handler_name, presence: true
  validates :location, presence: true
  validate :signature_required_for_delivery
  validate :signature_image_is_a_sane_png, on: :create

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
  def signature_image_is_a_sane_png
    image = signature_data.is_a?(Hash) ? signature_data["image"] : nil
    return if image.blank?

    errors.add(:signature_data, "image isn't a valid signature") unless self.class.sane_png_data_url?(image)
  end

  def self.sane_png_data_url?(data_url)
    return false unless data_url.is_a?(String) && data_url.length <= MAX_SIGNATURE_LENGTH

    match = SIGNATURE_DATA_URL.match(data_url)
    return false unless match

    bytes = Base64.strict_decode64(match[1])
    return false unless bytes.start_with?(PNG_MAGIC) && bytes.byteslice(12, 4) == "IHDR"

    width, height = bytes.byteslice(16, 8).unpack("NN")
    width.to_i.between?(1, MAX_SIGNATURE_DIMENSION) && height.to_i.between?(1, MAX_SIGNATURE_DIMENSION)
  rescue ArgumentError
    false
  end

  def signature_required_for_delivery
    return unless action_type == "delivered"
    return if signed?

    errors.add(:signature_data, "must include a signature and signer name to confirm delivery")
  end
end
