class CreateAlertRecipients < ActiveRecord::Migration[8.1]
  # Phone numbers an organization wants texted when one of its shipments
  # goes outside the 2-8°C range. Distinct from the always-on email alert
  # to admins/pharmacists -- SMS is opt-in, configured per org, and only
  # available on the Pro and Compliance tiers.
  def change
    create_table :alert_recipients do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :label, null: false
      t.string :phone, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :alert_recipients, %i[organization_id phone], unique: true
  end
end
