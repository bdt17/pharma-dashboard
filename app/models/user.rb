class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable, :confirmable

  # TOTP second factor (rotp-backed). Required for every user -- the gate that
  # enforces enrollment/challenge lives in ApplicationController#enforce_two_factor.
  include TwoFactorAuthentication

  # :confirmable normally requires every new user to click an emailed link
  # before they can sign in -- exactly the gate self-service signup needs
  # (see Users::RegistrationsController), but it would also block a user
  # created directly: from the Rails console, db/seeds.rb, or (nearly all
  # of) this app's own test suite, none of which go through a real signup
  # form or have a real inbox to confirm. Auto-confirm by default; the
  # signup controller explicitly opts a record *out* of that, so only the
  # actual public signup path is gated.
  attr_accessor :requires_email_confirmation
  before_validation :auto_confirm_unless_self_service_signup, on: :create

  # Same reasoning as requires_email_confirmation above: only the actual
  # public signup form has a Terms/Privacy checkbox for a person to check,
  # so this only applies there -- gated on the same flag rather than a
  # second one, since both mean exactly "this is the self-service signup
  # path." A console-created user, a seed, or a factory in the test suite
  # never sees or needs this.
  attr_accessor :terms_accepted
  # acceptance defaults allow_nil: true (so a checkbox the form never
  # submitted at all -- or bypassing the form entirely -- would otherwise
  # silently pass); explicit false here so a missing value is actually
  # rejected rather than treated as accepted.
  validates :terms_accepted, acceptance: { message: "must be accepted to create an account", allow_nil: false }, if: :requires_email_confirmation

  belongs_to :organization
  # Plain belongs_to only validates that organization isn't nil -- it does
  # NOT check that the associated record is itself valid. Matters here
  # because self-service signup builds a brand-new, unsaved Organization
  # inline (see Users::RegistrationsController); without this, a blank
  # organization name would silently save the user anyway with a broken
  # organization attached, instead of failing validation like it should.
  validates_associated :organization

  has_many :driven_batches, class_name: "Batch", foreign_key: "driver_id", inverse_of: :driver, dependent: :nullify
  has_many :generated_compliance_reports, class_name: "ComplianceReport", foreign_key: "generated_by_id", dependent: :restrict_with_error

  # role is a plain string column (see schema) so the enum values below are
  # stored as-is ("admin", "driver", ...) rather than Rails' usual integer
  # encoding -- readable directly in the database, and matches what was
  # already there before this enum existed.
  enum :role, {
    admin: "admin",
    dispatcher: "dispatcher",
    driver: "driver",
    pharmacist: "pharmacist"
  }, validate: true, default: "dispatcher"

  private

  def auto_confirm_unless_self_service_signup
    self.confirmed_at ||= Time.current unless requires_email_confirmation
  end

  # Devise's default send_devise_notification lets any delivery failure
  # (SMTP auth rejected, connection timeout, etc.) either raise -- crashing
  # signup/password-reset mid-request -- or, with
  # config.action_mailer.raise_delivery_errors = false, vanish with no log
  # line at all, which is exactly what made a real M365 SMTP timeout
  # invisible in production. Rescue explicitly so the failure is always
  # logged, regardless of that global flag, without ever breaking the
  # request that triggered it.
  def send_devise_notification(notification, *args)
    super
  rescue StandardError => e
    Rails.logger.error(
      "[DeviseMailer] Failed to send '#{notification}' to #{email.inspect}: #{e.class}: #{e.message}"
    )
  end
end
