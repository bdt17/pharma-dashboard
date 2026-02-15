class SubscriptionsController < ApplicationController
  def new
  end
  
  def create
    customer = Stripe::Customer.create(email: current_user.email)
    Stripe::Subscription.create(
      customer: customer.id,
      items: [{ price: "price_99_monthly_vehicle" }]
    )
    redirect_to dashboard_path, notice: "Premium activated!"
  end
end
