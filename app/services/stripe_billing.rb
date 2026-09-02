# Thin wrapper around the Stripe API calls billing actually needs. Plans
# are never hardcoded here -- pricing lives in Stripe's own dashboard as
# Products/Prices, and this just reflects whatever is active there. Keeping
# this in one place (rather than calling Stripe::* directly from
# BillingController) is what makes it possible to stub in tests without a
# real Stripe account or network access.
class StripeBilling
  class NotConfigured < StandardError; end

  # Every new subscription checkout (not the one-time addon) starts with a
  # 14-day trial, card required up front -- Stripe still collects payment
  # info in Checkout during a trial by default, it just doesn't charge
  # until the trial ends, which is what makes the trial convert to paid
  # automatically instead of needing anyone to follow up.
  TRIAL_PERIOD_DAYS = 14

  # Founding-customer launch offer, tied to the same Nov 27 2026 DSCSA
  # deadline the outreach mailer leans on: subscribe to the monthly plan
  # before the cutoff and get 25% off for the first 6 months after the
  # trial ends. Auto-applied in start_checkout! -- no promo code to
  # remember -- and only to the monthly plan (a "6 months" discount
  # doesn't map cleanly onto a once-a-year annual invoice). See
  # StripeFoundingCouponSync for where the actual Stripe Coupon comes
  # from; redeem_by there is set from this same cutoff, so the coupon
  # itself stops working at Stripe's end after this date even if
  # something here didn't.
  FOUNDING_OFFER_COUPON_ID = "founding-customer-25-off-6mo".freeze

  def self.founding_offer_cutoff
    Time.zone.local(2026, 10, 1).end_of_day
  end

  def self.configured?
    Stripe.api_key.present?
  end

  # [{ id:, product_name:, amount:, currency:, interval: }, ...] -- recurring
  # (subscription) Prices only. Predates available_addons below, back when
  # every active Price in Stripe happened to be a subscription plan, so
  # nothing filtered on :recurring here -- once a one-time addon Price
  # actually existed, it started leaking into this list too, offering a
  # "Subscribe" button for a Price Stripe can't put in subscription-mode
  # Checkout at all. select(&:recurring) is the fix; reject(&:recurring)
  # below is available_addons' mirror image of it.
  def self.available_plans
    return [] unless configured?

    Stripe::Price.list(active: true, expand: [ "data.product" ]).data
      .select(&:recurring)
      .map do |price|
        {
          id: price.id,
          product_name: price.product.name,
          amount: price.unit_amount / 100.0,
          currency: price.currency,
          interval: price.recurring.interval,
          tier: (price[:metadata] || {})["tier"]
        }
      end
  end

  # [{ id:, product_name:, amount:, currency: }, ...] -- the one-time
  # (non-subscription) counterpart to available_plans: the $149 / 10-pack
  # extra Compliance Packet credits, the White-Glove Setup service, and
  # whatever else gets added as a one-time Price later. Same rule: never
  # hardcoded here, just whatever's actually active in Stripe right now.
  def self.available_addons
    return [] unless configured?

    Stripe::Price.list(active: true, expand: [ "data.product" ]).data
      .reject(&:recurring)
      .map { |price| { id: price.id, product_name: price.product.name, amount: price.unit_amount / 100.0, currency: price.currency } }
  end

  # Ensures the organization has a Stripe Customer, creates a Checkout
  # Session for the given price, and returns the URL to redirect the user
  # to. The organization<->customer link (stripe_customer_id) is what lets
  # StripeWebhooksController match the subsequent customer.subscription.*
  # events back to the right organization.
  def self.start_checkout!(organization:, price_id:, success_url:, cancel_url:)
    with_checkout_retry(organization) do |customer_id|
      # founding_offer_discounts_for is computed inside the block, not
      # before with_checkout_retry is called: that's what makes
      # with_checkout_retry's own "raise NotConfigured unless configured?"
      # fire first when Stripe isn't set up, instead of this hitting the
      # API (the Price lookup) with no key.
      checkout_session(
        customer_id: customer_id, price_id: price_id, success_url: success_url, cancel_url: cancel_url,
        discounts: founding_offer_discounts_for(price_id)
      ).url
    end
  end

  # Same idea as start_checkout!, but a one-time payment (mode: "payment")
  # rather than a subscription -- covers every kind of one-time add-on
  # (single/bulk Compliance Packet credits, the White-Glove Setup service).
  # The metadata is how StripeWebhooksController tells these apart at
  # checkout.session.completed time; see addon_metadata_for for where it
  # comes from.
  def self.start_addon_checkout!(organization:, price_id:, success_url:, cancel_url:)
    raise NotConfigured unless configured?

    metadata = addon_metadata_for(Stripe::Price.retrieve(price_id))

    with_checkout_retry(organization) do |customer_id|
      checkout_session(
        customer_id: customer_id, price_id: price_id, success_url: success_url, cancel_url: cancel_url,
        mode: "payment", metadata: metadata
      ).url
    end
  end

  # A link to Stripe's own hosted Billing Portal -- lets an organization's
  # admin update a failed/expiring card, view past invoices, or cancel,
  # entirely on Stripe's side. Without this there was no self-serve way to
  # recover from a failed payment at all: the subscription would just slide
  # to past_due/unpaid and eventually cancel, with the only fix being an
  # email to support -- exactly the channel that's been unreliable this
  # session. Requires an existing Stripe Customer (a real checkout must
  # have already happened); raises plainly rather than silently creating
  # one, since a portal session for a customer with no subscription history
  # wouldn't have anything useful to show anyway.
  def self.billing_portal_url(organization:, return_url:)
    raise NotConfigured unless configured?
    raise ArgumentError, "organization has no Stripe customer yet" if organization.stripe_customer_id.blank?

    Stripe::BillingPortal::Session.create(customer: organization.stripe_customer_id, return_url: return_url).url
  end

  def self.create_customer!(organization)
    customer = Stripe::Customer.create(name: organization.name)
    organization.update!(stripe_customer_id: customer.id)
    customer.id
  end

  # Adds a single extra Compliance Packet to the organization's next
  # subscription invoice as a *pending* invoice item -- no immediate card
  # charge, it just rides along on the next monthly renewal. Priced off
  # the same one-time "Extra Compliance Packet" Stripe Price the Billing
  # page sells as a standalone credit, so there's one number to change.
  # Raises NotConfigured if Stripe or that Price isn't set up, or if the
  # organization has no Stripe customer yet -- ComplianceReportsController
  # treats any failure here as "block, don't hand out a free packet".
  def self.add_packet_overage_item!(organization:, description:)
    raise NotConfigured unless configured?
    raise NotConfigured, "organization has no Stripe customer" if organization.stripe_customer_id.blank?

    price = single_packet_price
    item = Stripe::InvoiceItem.create(
      customer: organization.stripe_customer_id,
      price: price.id,
      description: description
    )
    { invoice_item_id: item.id, amount_cents: price.unit_amount, currency: price.currency }
  end

  # The active one-time Price for a single extra Compliance Packet,
  # matched by product name the same way StripeAddonPriceSync finds it.
  def self.single_packet_price
    Stripe::Price.list(active: true, expand: [ "data.product" ]).data
      .find { |price| !price.recurring && price.product.name == StripeAddonPriceSync::PRODUCT_NAME } ||
      raise(NotConfigured, "no '#{StripeAddonPriceSync::PRODUCT_NAME}' Price in Stripe -- run stripe:sync_addon_prices")
  end

  # Shared by start_checkout! and start_addon_checkout!: ensures a Stripe
  # Customer exists, yields its id to build whatever Checkout Session the
  # caller needs, and retries once if the stored customer id turns out to
  # be stale.
  def self.with_checkout_retry(organization)
    raise NotConfigured unless configured?

    customer_id = organization.stripe_customer_id || create_customer!(organization)
    yield customer_id
  rescue Stripe::InvalidRequestError => e
    # A stored stripe_customer_id can go stale for reasons that have
    # nothing to do with this particular checkout attempt -- most likely
    # STRIPE_SECRET_KEY moved between test and live mode (customer IDs
    # are mode-specific, so a test-mode customer simply doesn't exist
    # once the key switches to live), or the customer was deleted
    # directly in the Stripe dashboard. Without this, every organization
    # that already had a customer_id saved would be permanently unable to
    # check out -- recreate the customer once and retry instead.
    raise unless stale_customer_error?(e)

    customer_id = create_customer!(organization)
    yield customer_id
  end
  private_class_method :with_checkout_retry

  def self.checkout_session(customer_id:, price_id:, success_url:, cancel_url:, mode: "subscription", metadata: {}, discounts: [])
    params = {
      customer: customer_id,
      mode: mode,
      line_items: [ { price: price_id, quantity: 1 } ],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: metadata
    }
    params[:subscription_data] = { trial_period_days: TRIAL_PERIOD_DAYS } if mode == "subscription"
    params[:discounts] = discounts if discounts.present?

    Stripe::Checkout::Session.create(params)
  end
  private_class_method :checkout_session

  # [] once the offer window has closed, or for any plan that isn't billed
  # monthly -- checked with the cheap date comparison first specifically
  # so this stops making an extra Stripe API call (the Price lookup) for
  # every checkout forever, not just once the offer no longer applies.
  def self.founding_offer_discounts_for(price_id)
    return [] if Time.current > founding_offer_cutoff
    return [] unless Stripe::Price.retrieve(price_id).recurring&.interval == "month"

    [ { coupon: FOUNDING_OFFER_COUPON_ID } ]
  end
  private_class_method :founding_offer_discounts_for

  def self.stale_customer_error?(error)
    error.code == "resource_missing" && error.param == "customer"
  end
  private_class_method :stale_customer_error?

  # Reads how this specific one-time Price should be handled once paid,
  # straight from the Price's own Stripe metadata rather than the caller
  # guessing -- a Price is the one thing every checkout for it shares, so
  # tagging it there (see the Stripe*PriceSync services) is the single
  # source of truth for what a completed checkout.session should do.
  # Defaults to "compliance_report_credit"/"1" for a Price created before
  # this tagging existed (the original $149 addon, live before this).
  def self.addon_metadata_for(price)
    # Hash-style access (not price.metadata) deliberately: a live Stripe
    # object always has a metadata key, but a Price with no metadata at
    # all raises NoMethodError on the dotted accessor rather than
    # returning nil -- [] is the safe way to ask "is this key set."
    price_metadata = price[:metadata] || {}
    kind = price_metadata["kind"] || "compliance_report_credit"
    metadata = { "kind" => kind }
    metadata["credit_quantity"] = price_metadata["credit_quantity"] || "1" if kind == "compliance_report_credit"
    metadata
  end
  private_class_method :addon_metadata_for
end
