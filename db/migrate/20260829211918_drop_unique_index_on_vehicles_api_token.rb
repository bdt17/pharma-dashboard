class DropUniqueIndexOnVehiclesApiToken < ActiveRecord::Migration[8.1]
  # api_token is moving to ActiveRecord Encryption (non-deterministic), so the
  # column stores a different ciphertext on every write even for the same
  # plaintext. A unique index on it can no longer do anything useful -- it
  # would never catch a duplicate. Nothing queries vehicles by api_token
  # either (device auth looks a vehicle up by imei, then compares the token in
  # Ruby), so the index is dropped entirely rather than made non-unique.
  #
  # The token itself is 32 bytes from SecureRandom, so a real collision is not
  # a threat model worth an index.
  def change
    remove_index :vehicles, :api_token, unique: true
  end
end
