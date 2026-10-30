# Device tokens become SHA-256 digests instead of (encrypted) plaintext:
# a stolen database plus the encryption keys still doesn't yield a token a
# device would accept. Existing tokens keep working -- each digest is
# computed from the decrypted current value -- so no tracker needs
# reconfiguring.
class HashVehicleApiTokens < ActiveRecord::Migration[8.1]
  class LegacyVehicle < ActiveRecord::Base
    self.table_name = "vehicles"
    encrypts :api_token
  end

  def up
    add_column :vehicles, :api_token_digest, :string

    LegacyVehicle.reset_column_information
    LegacyVehicle.where.not(api_token: nil).find_each do |vehicle|
      vehicle.update_columns(api_token_digest: OpenSSL::Digest::SHA256.hexdigest(current_token(vehicle)))
    end

    remove_column :vehicles, :api_token
  end

  # Production rows are all encrypted (vehicles:encrypt_api_tokens ran),
  # but a development database can still hold pre-encryption plaintext.
  def current_token(vehicle)
    vehicle.api_token
  rescue ActiveRecord::Encryption::Errors::Base
    vehicle.api_token_before_type_cast
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "device tokens are only stored as digests now"
  end
end
