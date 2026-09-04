# One row per email address that's opted out of marketing-style email --
# see the migration for why this is keyed by email rather than by
# whatever record (a DscsaAssessment, say) originated the send.
class EmailSuppression < ApplicationRecord
  before_validation :normalize_email

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def self.suppressed?(email)
    where(email: normalize(email)).exists?
  end

  # Idempotent -- clicking an unsubscribe link twice (a mail client
  # prefetching it, a retry) shouldn't raise on the uniqueness validation.
  def self.suppress!(email)
    find_or_create_by!(email: normalize(email))
  end

  def self.normalize(email)
    email.to_s.strip.downcase
  end

  private

  def normalize_email
    self.email = self.class.normalize(email)
  end
end
