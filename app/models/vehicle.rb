class Vehicle < ApplicationRecord
  belongs_to :organization
  has_many :batches
  has_many :telemetries, dependent: :destroy
  has_many :excursion_events, dependent: :nullify

  # Only a SHA-256 digest of the device token is stored. The plaintext
  # exists in memory right after create (#api_token, shown once on the
  # vehicle's edit page) and on the tracker itself, nowhere else. Device
  # auth looks a vehicle up by imei and compares digests -- see
  # Api::V1::GpsController#authenticate_device!.
  attr_reader :api_token

  validates :name, presence: true
  # A real IMEI is 15 digits. Format-checked only when present -- imei
  # stays optional (allow_blank) since a vehicle can be registered before
  # its tracker is in hand and the IMEI added later via #update.
  validates :imei, uniqueness: true, format: { with: /\A\d{15}\z/, message: "must be 15 digits" }, allow_blank: true

  before_create :generate_api_token

  # The delivery this vehicle is currently carrying: the most recent batch
  # that hasn't been marked delivered. Incoming GPS/sensor pings are
  # attributed to it (see Api::V1::GpsController#create) so a shipment's
  # compliance packet has a real temperature history and ExcursionMonitor
  # has something to alert on. nil when the truck isn't out on a run.
  def current_batch
    batches.where.not(status: "delivered").order(created_at: :desc).first
  end

  def self.digest_api_token(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  def api_token=(token)
    @api_token = token.presence
    self.api_token_digest = @api_token && self.class.digest_api_token(@api_token)
  end

  # Constant-time comparison so a mistyped/guessed token can't be detected
  # faster than a correct one via response-timing differences.
  def api_token_matches?(candidate)
    return false if api_token_digest.blank? || candidate.blank?

    ActiveSupport::SecurityUtils.secure_compare(api_token_digest, self.class.digest_api_token(candidate))
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32) if api_token_digest.blank?
  end
end
