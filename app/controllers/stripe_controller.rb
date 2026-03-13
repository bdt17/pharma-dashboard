class StripeController < ApplicationController
  def index
    render plain: "Stripe OK", layout: false
  end
end
