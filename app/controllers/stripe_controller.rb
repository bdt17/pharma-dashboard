class StripeController < ApplicationController
  def checkout
    session = Stripe::Checkout::Session.create({
      mode: 'subscription',
      line_items: [{
        price: 'price_1ABC123xyz', # Replace with your Stripe price ID
        quantity: 1
      }],
      mode: 'subscription',
      success_url: "#{root_url}?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: root_url
    })
    redirect_to session.url, allow_other_domain: true
  end
end
