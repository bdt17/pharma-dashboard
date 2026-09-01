class AddDunningTrackingToSubscriptions < ActiveRecord::Migration[8.1]
  # State for the payment-recovery ("dunning") email sequence: when the
  # last one went out, and how many have been sent this failure. Both
  # reset to nil/0 the moment the subscription goes active again, so a
  # later failure starts a fresh sequence. See Subscription#send_dunning_email!
  # and DunningSweepJob.
  def change
    add_column :subscriptions, :last_dunning_email_at, :datetime
    add_column :subscriptions, :dunning_email_count, :integer, null: false, default: 0
  end
end
