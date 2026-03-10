class StripeController < ApplicationController
  def new
    render layout: false
  end
  
  def checkout
    render plain: "STRIPE LIVE! Plan: #{params[:plan]} - Add your Stripe Price ID"
  end
end
