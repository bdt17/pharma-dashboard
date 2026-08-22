# Shows the organization's real subscription state, and -- now that
# STRIPE_SECRET_KEY can be configured -- lets an admin actually start a
# real Stripe Checkout session for one of whatever plans exist in Stripe's
# dashboard. Plans are never hardcoded in this app; see StripeBilling.
class BillingController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscription = current_organization&.subscriptions&.order(created_at: :desc)&.first
    @plans = @subscription&.active_or_trialing? ? [] : StripeBilling.available_plans
  end

  def checkout
    authorize_billing_admin!
    return if performed?

    url = StripeBilling.start_checkout!(
      organization: current_organization,
      price_id: params.require(:price_id),
      success_url: billing_success_url,
      cancel_url: billing_url
    )
    redirect_to url, allow_other_host: true
  rescue StripeBilling::NotConfigured
    redirect_to billing_path, alert: "Billing isn't configured yet -- no Stripe API key is set."
  end

  def success
  end

  def cancel
  end

  private

  def authorize_billing_admin!
    return if current_user.admin?

    redirect_to billing_path, alert: "Only an organization admin can manage billing."
  end
end
