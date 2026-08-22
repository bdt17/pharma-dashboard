class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable

  belongs_to :organization

  has_many :driven_batches, class_name: "Batch", foreign_key: "driver_id", inverse_of: :driver, dependent: :nullify

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
end
