class Vehicle < ApplicationRecord
  belongs_to :organization
  has_many :batches
  has_many :telemetries, dependent: :destroy
  has_many :excursion_events, dependent: :nullify

  # Encrypted at rest (ActiveRecord Encryption; keys configured in
  # config/application.rb, same as User#otp_secret). Non-deterministic --
  # device auth looks a vehicle up by imei and then compares the token in
  # Ruby (see Api::V1::GpsController#authenticate_device!), so nothing ever
  # queries by api_token. Existing plaintext rows keep working while
  # support_unencrypted_data is on; `bin/rails vehicles:encrypt_api_tokens`
  # migrates them.
  encrypts :api_token

  validates :imei, uniqueness: true, allow_nil: true

  before_create :generate_api_token

  # The delivery this vehicle is currently carrying: the most recent batch
  # that hasn't been marked delivered. Incoming GPS/sensor pings are
  # attributed to it (see Api::V1::GpsController#create) so a shipment's
  # compliance packet has a real temperature history and ExcursionMonitor
  # has something to alert on. nil when the truck isn't out on a run.
  def current_batch
    batches.where.not(status: "delivered").order(created_at: :desc).first
  end

  # Constant-time comparison so a mistyped/guessed token can't be detected
  # faster than a correct one via response-timing differences.
  def api_token_matches?(candidate)
    return false if api_token.blank? || candidate.blank?

    ActiveSupport::SecurityUtils.secure_compare(api_token, candidate)
  end

  private

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end
end
