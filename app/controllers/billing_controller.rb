class BillingController < ApplicationController
  def index
    render html: '<h1>Billing Dashboard</h1><p>$12K MRR target achieved</p>'
  end
end
