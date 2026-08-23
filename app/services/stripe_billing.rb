# Thin wrapper around the Stripe API calls billing actually needs. Plans
# are never hardcoded here -- pricing lives in Stripe's own dashboard as
# Products/Prices, and this just reflects whatever is active there. Keeping
# this in one place (rather than calling Stripe::* directly from
# BillingController) is what makes it possible to stub in tests without a
# real Stripe account or network access.
class StripeBilling
  class NotConfigured < StandardError; end

  def self.configured?
    Stripe.api_key.present?
  end

  # [{ id:, product_name:, amount:, currency:, interval: }, ...]
  def self.available_plans
    return [] unless configured?

    Stripe::Price.list(active: true, expand: [ "data.product" ]).data.map do |price|
      {
        id: price.id,
        product_name: price.product.name,
        amount: price.unit_amount / 100.0,
        currency: price.currency,
        interval: price.recurring&.interval
      }
    end
  end

  # Ensures the organization has a Stripe Customer, creates a Checkout
  # Session for the given price, and returns the URL to redirect the user
  # to. The organization<->customer link (stripe_customer_id) is what lets
  # StripeWebhooksController match the subsequent customer.subscription.*
  # events back to the right organization.
  def self.start_checkout!(organization:, price_id:, success_url:, cancel_url:)
    raise NotConfigured unless configured?

    customer_id = organization.stripe_customer_id || create_customer!(organization)
    checkout_session(customer_id: customer_id, price_id: price_id, success_url: success_url, cancel_url: cancel_url).url
  rescue Stripe::InvalidRequestError => e
    # A stored stripe_customer_id can go stale for reasons that have
    # nothing to do with this particular checkout attempt -- most likely
    # STRIPE_SECRET_KEY moved between test and live mode (customer IDs
    # are mode-specific, so a test-mode customer simply doesn't exist
    # once the key switches to live), or the customer was deleted
    # directly in the Stripe dashboard. Without this, every organization
    # that already had a customer_id saved would be permanently unable to
    # subscribe -- recreate the customer once and retry instead.
    raise unless stale_customer_error?(e)

    customer_id = create_customer!(organization)
    checkout_session(customer_id: customer_id, price_id: price_id, success_url: success_url, cancel_url: cancel_url).url
  end

  def self.create_customer!(organization)
    customer = Stripe::Customer.create(name: organization.name)
    organization.update!(stripe_customer_id: customer.id)
    customer.id
  end

  def self.checkout_session(customer_id:, price_id:, success_url:, cancel_url:)
    Stripe::Checkout::Session.create(
      customer: customer_id,
      mode: "subscription",
      line_items: [ { price: price_id, quantity: 1 } ],
      success_url: success_url,
      cancel_url: cancel_url
    )
  end
  private_class_method :checkout_session

  def self.stale_customer_error?(error)
    error.code == "resource_missing" && error.param == "customer"
  end
  private_class_method :stale_customer_error?
end
