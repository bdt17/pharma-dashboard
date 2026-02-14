class BillingController < ApplicationController
  def index
    render plain: "$4,653 MRR - Thomas IT Pharma", status: :ok
  end
end
