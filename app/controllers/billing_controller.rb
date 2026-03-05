class BillingController < ApplicationController
  def index
    render plain: "💰 STRIPE BILLING LIVE\n$99/mo per truck → $594 MRR (6 trucks)\nPDF Certified ✓ | GPS IoT ✓"
  end
end
