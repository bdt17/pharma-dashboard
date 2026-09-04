# One-time-per-plan-change setup step (not something a request path calls):
# given the recurring monthly Prices already configured in Stripe for each
# Product, ensures a matching annual Price exists on the same Product priced
# at ANNUAL_FREE_MONTHS fewer months than 12 -- "2 months free," not a
# percentage discount (was 10% off until this pricing decision). Same
# "pricing lives in Stripe, not this app" rule StripeBilling.available_plans
# already follows -- this just keeps a monthly Product's annual variant in
# sync there too, instead of someone having to hand-create it correctly in
# the Stripe dashboard. Run via `bin/rails stripe:sync_annual_prices` after
# adding or changing a plan.
class StripeAnnualPriceSync
  ANNUAL_FREE_MONTHS = 2

  Result = Struct.new(:created, keyword_init: true)

  def self.call
    new.call
  end

  def call
    created = monthly_prices.filter_map { |price| ensure_annual_price_for(price) }
    Result.new(created: created)
  end

  private

  def monthly_prices
    Stripe::Price.list(active: true, limit: 100, recurring: { interval: "month" }, expand: [ "data.product" ]).data
  end

  # Skips a Product that already has an active annual Price rather than
  # creating a second one -- makes the task safe to run repeatedly (e.g.
  # in a deploy step) instead of only being safe to run exactly once.
  def ensure_annual_price_for(monthly_price)
    product_id = monthly_price.product.id
    return nil if annual_price_exists?(product_id)

    Stripe::Price.create(
      product: product_id,
      unit_amount: annual_amount_for(monthly_price),
      currency: monthly_price.currency,
      recurring: { interval: "year" },
      metadata: annual_metadata_for(monthly_price)
    )
  end

  # Carries the monthly Price's tier tag over to its annual variant.
  # BillingController now allow-lists @plans by tier (so an untagged
  # Price -- an abandoned experiment, a duplicate, Enterprise -- never
  # renders as a self-serve Subscribe button); every annual Price created
  # before this method existed had no tier at all, which under that
  # allow-list would have hidden the real annual plans too, not just the
  # ones that should stay hidden. Omitted (not sent as "") when the
  # monthly Price itself has no tier, rather than writing an empty
  # metadata value.
  def annual_metadata_for(monthly_price)
    tier = (monthly_price[:metadata] || {})["tier"]
    tier.present? ? { "tier" => tier } : {}
  end

  def annual_amount_for(monthly_price)
    monthly_price.unit_amount * (12 - ANNUAL_FREE_MONTHS)
  end

  def annual_price_exists?(product_id)
    Stripe::Price.list(active: true, limit: 100, product: product_id, recurring: { interval: "year" }).data.any?
  end
end
