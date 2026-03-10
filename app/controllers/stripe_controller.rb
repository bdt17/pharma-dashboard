class StripeController < ApplicationController
  def new
    render inline: "<h1>Pharma Transport - Choose Plan</h1>"
  end
  
  def success
    render inline: "<h1>✅ Subscription Success!</h1>"
  end
end
