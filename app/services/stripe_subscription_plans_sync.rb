# One-time-per-setup script (not something a request path calls): ensures
# a Stripe Product + monthly Price exists for each subscription tier
# defined in SubscriptionPlan. Same shape as the other Stripe*Sync
# services -- idempotent, matches an existing Product by name and an
# existing monthly Price by product, and never mutates a Price that's
# already live (retire and recreate instead). Run via
# `bin/rails stripe:sync_subscription_plans`. StripeAnnualPriceSync then
# fills in the 10%-off annual Price for each.
class StripeSubscriptionPlansSync
  Result = Struct.new(:created, :existing, keyword_init: true)

  def self.call
    new.call
  end

  def call
    created = []
    existing = []

    SubscriptionPlan::ALL.each do |plan|
      product = find_or_create_product(plan)
      price = monthly_price_for(product)

      if price
        existing << price
      else
        created << create_monthly_price(product, plan)
      end
    end

    Result.new(created: created, existing: existing)
  end

  private

  def find_or_create_product(plan)
    active_products.find { |p| p.name == plan.name } ||
      Stripe::Product.create(
        name: plan.name,
        description: plan.tagline,
        metadata: { "tier" => plan.tier }
      )
  end

  def create_monthly_price(product, plan)
    Stripe::Price.create(
      product: product.id,
      unit_amount: plan.monthly_cents,
      currency: "usd",
      recurring: { interval: "month" },
      metadata: {
        "tier" => plan.tier,
        "packet_allowance" => plan.packet_allowance&.to_s || "unlimited"
      }
    )
  end

  # Only a monthly recurring price -- the annual variant is
  # StripeAnnualPriceSync's job and must not be treated as "already done"
  # here.
  def monthly_price_for(product)
    active_prices.find do |price|
      price.product == product.id && price.recurring&.interval == "month"
    end
  end

  def active_products
    @active_products ||= Stripe::Product.list(active: true).data
  end

  def active_prices
    @active_prices ||= Stripe::Price.list(active: true).data
  end
end
