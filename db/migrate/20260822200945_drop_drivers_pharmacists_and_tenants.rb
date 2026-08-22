class DropDriversPharmacistsAndTenants < ActiveRecord::Migration[8.1]
  def change
    # Driver and Pharmacist were separate Devise-enabled tables with
    # identical auth modules to User and no role logic distinguishing them.
    # Only `devise_for :users` was ever routed, so neither was reachable as
    # its own login. Consolidated into `users.role` instead (see Phase 2).
    # No production signups exist on either table (confirmed before writing
    # this migration), so this is a direct drop rather than a backfill.
    drop_table :drivers, force: :cascade do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.timestamps
    end

    drop_table :pharmacists, force: :cascade do |t|
      t.string :email, default: "", null: false
      t.string :encrypted_password, default: "", null: false
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.timestamps
      t.index :email, unique: true
      t.index :reset_password_token, unique: true
    end

    # `tenants` had no model and nothing referenced it — Organization is the
    # one real tenant concept in this app (see Phase 1 audit).
    drop_table :tenants, force: :cascade do |t|
      t.string :name
      t.timestamps
    end
  end
end
