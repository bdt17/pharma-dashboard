class StripeController < ApplicationController
  def new
  end
  
  def checkout
    render plain: "STRIPE CHECKOUT LIVE - #{params[:plan]}"
  end
end
