class CustodyLog < ApplicationRecord
  belongs_to :batch
  # The signed-in user who recorded the event. Optional only because rows
  # from before this was tracked have none.
  belongs_to :recorded_by, class_name: "User", optional: true

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
  # Browser GPS from driver mode: both coordinates or neither.
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validates :latitude, presence: true, if: -> { longitude.present? }
  validates :longitude, presence: true, if: -> { latitude.present? }
  validates :location_accuracy_m, numericality: { only_integer: true, in: 0..100_000 }, allow_nil: true
  # A hand-held probe reading. Wide enough for frozen product and a hot
  # car, narrow enough to catch a typo like 47 for 4.7.
  validates :temperature_celsius, numericality: { in: -40..60 }, allow_nil: true
  validate :signature_image_is_a_sane_png, on: :create

  before_validation :set_timestamp, on: :create
  # A driver at a doorstep may not know the street address -- the GPS fix
  # is a better location record than nothing.
  before_validation :default_location_to_gps, on: :create

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

  def gps?
    latitude.present? && longitude.present?
  end

  def gps_label
    return unless gps?

    label = "#{latitude.round(5)}, #{longitude.round(5)}"
    location_accuracy_m ? "#{label} (±#{location_accuracy_m} m)" : label
  end

  def map_url
    "https://www.openstreetmap.org/?mlat=#{latitude}&mlon=#{longitude}#map=17/#{latitude}/#{longitude}" if gps?
  end

  # 2-8 °C is the refrigerated range nearly all cold-chain product in a
  # pharmacy's deliveries is labelled for; a reading outside it is flagged
  # on the record, not blocked -- the product might legitimately be frozen
  # or room temperature.
  def temperature_outside_refrigerated_range?
    temperature_celsius.present? && !(2..8).cover?(temperature_celsius)
  end

  private

  def set_timestamp
    self.timestamp ||= Time.current
  end

  def default_location_to_gps
    self.location = "GPS #{gps_label}" if location.blank? && gps?
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
