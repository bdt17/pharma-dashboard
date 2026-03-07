require 'stripe'

class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_test
  
  def create_intent
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    
    intent = Stripe::PaymentIntent.create({
      amount: params[:amount].to_i,
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      metadata: params[:metadata]&.permit!.to_h || {}
    })
    
    render json: { 
      client_secret: intent.client_secret,
      intent_id: intent.id 
    }
  rescue Stripe::StripeError => e
    render json: { error: e.message }, status: 400
  rescue => e
    render json: { error: e.message }, status: 500
  end
  
  def webhook_test
    head :ok
  end
end
