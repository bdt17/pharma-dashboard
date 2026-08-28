class AddMfaToUsers < ActiveRecord::Migration[8.1]
  def change
    # TOTP shared secret (base32). Stored in plaintext: this app has no
    # ActiveRecord encryption configured (there is no config/master.key), the
    # same situation as the existing plaintext vehicles.api_token column.
    # Follow-up: wrap this in `encrypts :otp_secret` once credentials exist.
    add_column :users, :otp_secret, :string

    # False until the user finishes enrollment (scans the QR and confirms one
    # code). Two-factor is required for every user, so a false value here means
    # "force this user through setup before any authenticated page".
    add_column :users, :otp_enabled, :boolean, null: false, default: false
    add_column :users, :otp_enabled_at, :datetime

    # JSON array of BCrypt digests of the one-time backup codes.
    add_column :users, :otp_backup_codes, :text

    # Highest TOTP counter this user has already spent, so a code that is still
    # inside its validity window cannot be replayed a second time.
    add_column :users, :otp_consumed_timestep, :integer
  end
end
