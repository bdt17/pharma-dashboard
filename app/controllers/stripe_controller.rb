class StripeController < ApplicationController
  def create_checkout_session
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    session = Stripe::Checkout::Session.create({
      mode: 'subscription',
      line_items: [{price: 'price_vehicle_plan', quantity: 1}],
      success_url: root_url,
      cancel_url: billing_url,
    })
    redirect_to session.url, allow_other_host: true
  end
end
