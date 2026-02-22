class BillingController < ApplicationController
  def index
    render plain: 'Stripe $99/mo per vehicle - $499 enterprise'
  end
end
