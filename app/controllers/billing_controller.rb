class BillingController < ApplicationController
  def index
    # Stripe $99/mo pharma subscription
    @stripe_price_id = "price_12345" # Add your Stripe Price ID
  end
end
