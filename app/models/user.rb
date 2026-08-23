class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable, :confirmable

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
end
