class AddOrganizationAndSecurityFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :organization, foreign_key: true

    # Devise :lockable
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime
    add_index :users, :unlock_token, unique: true

    # `tenant_id` was a free-text string with no FK, unused by any query in
    # the app, and duplicated the concept `organization_id` now covers
    # properly (with referential integrity). See the Phase 1 audit.
    remove_column :users, :tenant_id, :string
  end
end
