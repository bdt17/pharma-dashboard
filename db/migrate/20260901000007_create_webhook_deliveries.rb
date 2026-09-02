class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.string :event, null: false
      # The envelope id -- what the receiver dedupes on. Not unique here:
      # a replay of the same event is a second row with the same event_id.
      t.string :event_id, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.integer :response_status
      t.string :error
      t.integer :attempts, null: false, default: 0
      t.integer :duration_ms
      t.datetime :completed_at
      # Points at the delivery this one is a manual re-send of, if any.
      t.bigint :replayed_from_id

      t.timestamps
    end

    add_index :webhook_deliveries, [ :webhook_endpoint_id, :created_at ]
    add_index :webhook_deliveries, :event_id
  end
end
