class SubscriptionsController < ApplicationController
  def index
    # MVP: Show plans WITHOUT Stripe API calls
    @plans = [
      { name: 'Pro', price: '$99/mo', features: ['✅ Unlimited CoC PDFs', '✅ Live GPS tracking', '✅ DSCSA reports'] },
      { name: 'Enterprise', price: '$499/mo', features: ['✅ Multi-tenant', '✅ API access', '✅ Custom SLAs'] }
    ]
  end

  def new
    # Stripe checkout (ONLY when key configured)
    if ENV['STRIPE_SECRET_KEY'].present? || Rails.application.credentials.dig(:stripe, :secret_key)
      session = Stripe::Checkout::Session.create({
        mode: 'subscription',
        line_items: [{ price: 'price_1ABC123', quantity: 1 }], # Replace with real price ID
        success_url: "#{root_url}billing?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: root_url,
      })
      redirect_to session.url, allow_other_host: true
    else
      flash[:notice] = "Pro plan coming soon! Contact sales@pharmatransport.org"
      redirect_to root_path
    end
  end

  def create
    head 200
  end
end
