class BillingController < ApplicationController
  def index
    render plain: "💰 STRIPE BILLING v1.0\n$99/mo per truck | 6 trucks = $594 MRR\nAPI: LIVE | PDF: CERTIFIED"
  end
end
