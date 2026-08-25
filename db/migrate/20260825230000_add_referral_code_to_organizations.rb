class AddReferralCodeToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :referral_code, :string
    add_index :organizations, :referral_code, unique: true
  end
end
