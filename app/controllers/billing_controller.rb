class BillingController < ApplicationController
  def index; render plain: "Billing → $99/mo vehicle ready"; end
  def plans; render plain: "Basic $99 | Enterprise $499"; end
  def subscribe; render plain: "Stripe checkout ready"; end
end
