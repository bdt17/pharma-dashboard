# Shows the organization's real subscription state, and -- now that
# STRIPE_SECRET_KEY can be configured -- lets an admin actually start a
# real Stripe Checkout session for one of whatever plans exist in Stripe's
# dashboard. Plans are never hardcoded in this app; see StripeBilling.
class BillingController < ApplicationController
  before_action :authenticate_user!

  def index
    @subscription = current_organization&.subscriptions&.order(created_at: :desc)&.first
    unlimited = @subscription&.active_or_trialing?
    # Contact-sales tiers (Enterprise) have a live Stripe Price so a
    # subscription can be created for them by hand, but they're not
    # offered as a self-serve Subscribe button -- the page links to the
    # "talk to us" form instead.
    @plans = unlimited ? [] : StripeBilling.available_plans.reject { |plan| SubscriptionPlan.find(plan[:tier])&.contact_sales? }
    @addons = unlimited ? [] : StripeBilling.available_addons
    @available_credits = current_organization&.report_credits&.available&.count || 0
    # The overage toggle only makes sense on a capped paid plan -- an
    # unlimited plan has no allowance to exceed, and the free tier should
    # subscribe rather than pay per packet.
    @current_plan = current_organization&.current_plan
    @overage_eligible = @current_plan&.packet_allowance.present?
    @overages_this_month = current_organization&.packet_overages&.this_month || PacketOverage.none
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

  def addon_checkout
    authorize_billing_admin!
    return if performed?

    url = StripeBilling.start_addon_checkout!(
      organization: current_organization,
      price_id: params.require(:price_id),
      success_url: billing_success_url,
      cancel_url: billing_url
    )
    redirect_to url, allow_other_host: true
  rescue StripeBilling::NotConfigured
    redirect_to billing_path, alert: "Billing isn't configured yet -- no Stripe API key is set."
  end

  # Hands off to Stripe's own hosted portal for updating a payment method,
  # viewing invoices, or canceling -- see StripeBilling.billing_portal_url.
  # Any signed-in org member can open it (not just admin): it's read-mostly
  # (invoice history) plus self-service actions on their own org's billing,
  # not a distinct administrative action like starting a new subscription.
  def portal
    unless current_organization&.stripe_customer_id.present?
      redirect_to billing_path, alert: "No billing history yet -- subscribe first."
      return
    end

    url = StripeBilling.billing_portal_url(organization: current_organization, return_url: billing_url)
    redirect_to url, allow_other_host: true
  rescue StripeBilling::NotConfigured
    redirect_to billing_path, alert: "Billing isn't configured yet -- no Stripe API key is set."
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error("BillingController#portal: #{e.class}: #{e.message}")
    redirect_to billing_path, alert: "Couldn't open the billing portal right now. Try again shortly."
  end

  # Opt in / out of overage billing -- letting a capped plan (Starter /
  # Pro) generate Compliance Packets past its monthly allowance, each
  # billed as an extra on the next invoice instead of being blocked.
  def overage
    authorize_billing_admin!
    return if performed?

    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])
    current_organization.update!(overage_billing_enabled: enabled)
    redirect_to billing_path,
                notice: enabled ? "Overage billing is on. Extra packets will be added to your next invoice." :
                                  "Overage billing is off. Your plan will block at its monthly allowance."
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
