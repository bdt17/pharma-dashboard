class StripeController < ApplicationController
  def index
    render plain: "Stripe Billing: $99/mo Pharma Pro", layout: false, status: 200
  end
end
