class Vehicle < ApplicationRecord
  belongs_to :organization
  has_many :batches
  has_many :telemetries, dependent: :destroy

  validates :imei, uniqueness: true, allow_nil: true
  validates :api_token, uniqueness: true, allow_nil: true

  before_create :generate_api_token

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
