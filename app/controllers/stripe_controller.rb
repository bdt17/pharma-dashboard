class StripeController < ApplicationController
  def index
    render plain: "Stripe OK", status: 200
  end
end
