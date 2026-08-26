class AddVerificationTokenToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :verification_token, :string
    add_index :organizations, :verification_token, unique: true
  end
end
