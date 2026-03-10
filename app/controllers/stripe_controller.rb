class StripeController < ApplicationController
  def new
    render file: 'stripe/new', layout: false
  end
  
  def checkout
    # Replace with your Stripe Price IDs from dashboard
    price_id = case params[:plan]
    when 'pharmacy_pro_99' then 'price_123' # ← YOUR STRIPE PRICE ID
    end
    
    session = Stripe::Checkout::Session.create({
      mode: 'subscription',
      line_items: [{ price: price_id, quantity: 1 }],
      success_url: "#{root_url}subscribe/success",
      cancel_url: root_url
    })
    
    redirect_to session.url, allow_other_host: true
  end
end
