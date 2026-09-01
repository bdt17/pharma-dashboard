class Organization < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :vehicles, dependent: :restrict_with_error
  has_many :batches, dependent: :restrict_with_error
  has_many :subscriptions, dependent: :destroy
  has_many :compliance_reports, dependent: :restrict_with_error
  has_many :report_credits, dependent: :destroy
  has_many :alert_recipients, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_many :referrals_made, class_name: "Referral", foreign_key: :referrer_organization_id, inverse_of: :referrer_organization, dependent: :destroy
  has_one :referral_received, class_name: "Referral", foreign_key: :referred_organization_id, inverse_of: :referred_organization, dependent: :destroy

  validates :name, presence: true
  validates :referral_code, uniqueness: true, allow_nil: true
  validates :verification_token, uniqueness: true, allow_nil: true

  before_validation :assign_referral_code, on: :create
  before_validation :assign_verification_token, on: :create

  # Case-insensitive lookup, since a code shared in an email/postcard will
  # get typed by hand -- rejecting "abc123" for not matching "ABC123"
  # exactly would just look like a bug to whoever typed it.
  def self.find_by_referral_code(code)
    return nil if code.blank?

    find_by("upper(referral_code) = ?", code.strip.upcase)
  end

  # Whether this organization is currently a real, in-good-standing
  # customer -- the one thing VerificationsController shows publicly.
  # Same standard as ComplianceReportQuota's unlimited? (active or
  # trialing counts): a 14-day trial still means someone's actually using
  # the app to track a real shipment, not just browsing a marketing page.
  def verified?
    subscriptions.order(created_at: :desc).first&.active_or_trialing? || false
  end

  # The organization's current plan (SubscriptionPlan), or nil if there's
  # no active/trialing subscription or it predates tiers.
  def current_plan
    sub = subscriptions.order(created_at: :desc).first
    sub&.active_or_trialing? ? sub.plan : nil
  end

  # SMS excursion alerts are a Pro/Compliance-tier feature. A pre-tier
  # subscription (current_plan nil despite an active sub) is treated as
  # full-featured, the same way ComplianceReportQuota treats it as
  # unlimited.
  def alert_sms_available?
    sub = subscriptions.order(created_at: :desc).first
    return false unless sub&.active_or_trialing?

    plan = sub.plan
    plan.nil? || %w[pro compliance].include?(plan.tier)
  end

  # Outbound event webhooks are a Compliance-tier feature (the "handle the
  # deadline for me" plan) -- the integration an Enterprise buyer expects.
  # A pre-tier subscription counts, matching alert_sms_available?.
  def webhooks_available?
    sub = subscriptions.order(created_at: :desc).first
    return false unless sub&.active_or_trialing?

    plan = sub.plan
    plan.nil? || plan.tier == "compliance"
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

  # Much higher entropy than referral_code deliberately: that one's meant
  # to be read aloud and typed by hand, this one only ever appears as a
  # URL nobody types -- and unlike a referral code, guessing someone
  # else's would let a stranger read (a low-stakes, but still not
  # nobody's-business) fact about their subscription status.
  def assign_verification_token
    return if verification_token.present?

    attempts = 0
    begin
      attempts += 1
      self.verification_token = SecureRandom.urlsafe_base64(16)
    end while Organization.exists?(verification_token: verification_token) && attempts < 5
  end
end
