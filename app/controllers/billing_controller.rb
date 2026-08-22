class BillingController < ApplicationController
  def index
    render plain: "Billing OK", layout: false
  end
end
