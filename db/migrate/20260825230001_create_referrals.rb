class CreateReferrals < ActiveRecord::Migration[8.1]
  def change
    create_table :referrals do |t|
      t.references :referrer_organization, null: false, foreign_key: { to_table: :organizations }
      # An organization can only ever be the *referred* side once -- unique
      # index enforces that at the database level, not just in app code.
      t.references :referred_organization, null: false, foreign_key: { to_table: :organizations }, index: { unique: true }
      t.datetime :rewarded_at

      t.timestamps
    end
  end
end
