class CreateWebhookEndpoints < ActiveRecord::Migration[8.1]
  # Where an organization wants excursion + custody events POSTed (its WMS
  # / ERP). One HMAC signing secret per endpoint; auto-disabled after a run
  # of consecutive failures so a dead URL doesn't retry forever. Compliance
  # tier only -- see Organization#webhooks_available?.
  def change
    create_table :webhook_endpoints do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :url, null: false
      t.string :signing_secret, null: false
      t.boolean :active, null: false, default: true
      t.integer :consecutive_failures, null: false, default: 0
      t.datetime :last_success_at
      t.datetime :last_failure_at
      t.string :last_error
      t.timestamps
    end

    add_index :webhook_endpoints, %i[organization_id url], unique: true
  end
end
