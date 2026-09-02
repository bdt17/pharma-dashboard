class CreatePacketOverages < ActiveRecord::Migration[8.1]
  def change
    # Opt-in: an admin turns this on from the Billing page. Off means a
    # capped plan blocks at its monthly allowance exactly as before.
    add_column :organizations, :overage_billing_enabled, :boolean, null: false, default: false

    create_table :packet_overages do |t|
      t.references :organization, null: false, foreign_key: true
      # One overage row per generated packet -- the unique index is the
      # idempotency guard so a retried request can't double-bill.
      t.references :compliance_report, null: false, foreign_key: true, index: { unique: true }
      t.string :stripe_invoice_item_id, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "usd"

      t.timestamps
    end
  end
end
