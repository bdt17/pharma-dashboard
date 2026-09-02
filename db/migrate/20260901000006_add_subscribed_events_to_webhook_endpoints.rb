class AddSubscribedEventsToWebhookEndpoints < ActiveRecord::Migration[8.1]
  def change
    # An empty array means "every event type" -- the behaviour every
    # existing endpoint had before per-event filtering, so no backfill is
    # needed.
    add_column :webhook_endpoints, :subscribed_events, :string, array: true, null: false, default: []
  end
end
