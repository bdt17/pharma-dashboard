class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.references :user, foreign_key: true
      t.string :email, null: false
      t.string :role, null: false
      # SHA-256 of the emailed token; the token itself is never stored.
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :invitations, :token_digest, unique: true
    add_index :invitations, [ :organization_id, :email ]
  end
end
