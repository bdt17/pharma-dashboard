# An organization admin asking someone to join their organization -- the
# only way a second person gets into an existing organization (public
# signup always creates a new one; see Users::RegistrationsController).
#
# The emailed link carries a random token; only its SHA-256 digest is
# stored, so a database read alone can't be turned into a working link.
# The raw token exists in memory right after create (#token) and in the
# email itself, nowhere else. Accepting proves the person controls the
# invited address, so the new user is created already confirmed.
class Invitation < ApplicationRecord
  EXPIRES_IN = 7.days
  # Per organization, at once -- enough for any real pharmacy's staff, low
  # enough that a compromised admin account can't become a mail cannon.
  MAX_PENDING = 25

  belongs_to :organization
  belongs_to :invited_by, class_name: "User"
  belongs_to :user, optional: true

  attr_reader :token

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: User.roles.keys }
  validates :token_digest, :expires_at, presence: true
  validate :email_not_already_a_user, on: :create
  validate :not_already_invited, on: :create
  validate :under_pending_limit, on: :create

  before_validation :generate_token, on: :create

  scope :pending, -> { where(accepted_at: nil, revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  def self.find_pending_by_token(token)
    return nil if token.blank?

    pending.find_by(token_digest: digest(token))
  end

  def pending?
    accepted_at.nil? && revoked_at.nil? && expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  # A fresh token and a fresh 7 days, for "resend". The old link stops
  # working, so a forwarded or leaked copy of the first email is dead.
  def regenerate_token!
    generate_token(force: true)
    save!
  end

  # Creates the member and marks the invitation used, atomically. Returns
  # the User -- persisted on success; otherwise unsaved and carrying the
  # errors to re-render the form with.
  def accept!(name:, password:, password_confirmation:, terms_accepted:)
    member = organization.users.build(
      email: email, name: name, role: role,
      password: password, password_confirmation: password_confirmation
    )

    unless ActiveModel::Type::Boolean.new.cast(terms_accepted)
      member.errors.add(:base, "Please accept the Terms of Service and Privacy Policy")
      return member
    end

    with_lock do
      unless pending?
        member.errors.add(:base, "This invitation is no longer valid")
        raise ActiveRecord::Rollback
      end
      raise ActiveRecord::Rollback unless member.save

      update!(accepted_at: Time.current, user: member)
    end
    member
  rescue ActiveRecord::RecordNotUnique
    member.errors.add(:email, "already has an account")
    member
  end

  private

  def generate_token(force: false)
    return if token_digest.present? && !force

    @token = SecureRandom.urlsafe_base64(32)
    self.token_digest = self.class.digest(@token)
    self.expires_at = EXPIRES_IN.from_now
  end

  # One account belongs to exactly one organization, so an address that
  # already signed up anywhere can't be moved over by invite. Only an
  # organization admin ever sees this message.
  def email_not_already_a_user
    return unless email.present? && User.exists?(email: email)

    errors.add(:email, "already has a Pharma Transport account. Each account belongs to one organization, so invite a different address")
  end

  def not_already_invited
    return unless organization && email.present?
    return unless organization.invitations.pending.exists?(email: email)

    errors.add(:email, "already has a pending invitation. Use Resend instead")
  end

  def under_pending_limit
    return unless organization
    return if organization.invitations.pending.count < MAX_PENDING

    errors.add(:base, "You have #{MAX_PENDING} invitations pending. Revoke some before sending more")
  end
end
