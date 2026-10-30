class AddStripeEventAtToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    # The `created` time of the newest Stripe event applied to this row, so
    # an older event delivered late can't overwrite newer state.
    add_column :subscriptions, :stripe_event_at, :datetime
  end
end
