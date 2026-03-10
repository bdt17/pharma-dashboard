class StripeController < ApplicationController
  def new
    render layout: false
  end
  
  def checkout
    render plain: "STRIPE LIVE! Plan: #{params[:plan]} - Add Stripe Price ID to go live"
  end
end
