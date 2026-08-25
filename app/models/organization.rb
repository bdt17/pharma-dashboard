class Organization < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :vehicles, dependent: :restrict_with_error
  has_many :batches, dependent: :restrict_with_error
  has_many :subscriptions, dependent: :destroy
  has_many :compliance_reports, dependent: :restrict_with_error
  has_many :report_credits, dependent: :destroy
  has_many :referrals_made, class_name: "Referral", foreign_key: :referrer_organization_id, inverse_of: :referrer_organization, dependent: :destroy
  has_one :referral_received, class_name: "Referral", foreign_key: :referred_organization_id, inverse_of: :referred_organization, dependent: :destroy

  validates :name, presence: true
  validates :referral_code, uniqueness: true, allow_nil: true

  before_validation :assign_referral_code, on: :create

  # Case-insensitive lookup, since a code shared in an email/postcard will
  # get typed by hand -- rejecting "abc123" for not matching "ABC123"
  # exactly would just look like a bug to whoever typed it.
  def self.find_by_referral_code(code)
    return nil if code.blank?

    find_by("upper(referral_code) = ?", code.strip.upcase)
  end

  private

  # Retries on the rare collision the same way ComplianceReport retries a
  # version race -- the unique index is the real safety net, this just
  # means a collision doesn't surface as a raw uniqueness validation error
  # on an attribute nobody filled in themselves.
  def assign_referral_code
    return if referral_code.present?

    attempts = 0
    begin
      attempts += 1
      self.referral_code = SecureRandom.alphanumeric(8).upcase
    end while Organization.exists?(referral_code: referral_code) && attempts < 5
  end
end
