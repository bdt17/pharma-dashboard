# One-time-per-setup script (not something a request path calls): ensures
# a "Extra Compliance Packet" Stripe Product and one-time $149 Price exist,
# so the add-on offered on the Billing page (see BillingController,
# StripeBilling.available_addons) is actually purchasable. Same idea as
# StripeAnnualPriceSync, applied to this one-time price instead of an
# annual subscription variant. Run via
# `bin/rails stripe:sync_addon_prices`.
class StripeAddonPriceSync
  PRODUCT_NAME = "Extra Compliance Packet".freeze
  AMOUNT_CENTS = 14_900

  def self.call
    new.call
  end

  def call
    return existing_price if existing_price

    # kind/credit_quantity are also StripeBilling's *defaults* when a
    # one-time Price has no metadata at all (see
    # StripeBilling.addon_metadata_for), so tagging them here is belt and
    # suspenders for a fresh environment -- it doesn't retag the price
    # that's already live without them.
    Stripe::Price.create(
      product: product.id, unit_amount: AMOUNT_CENTS, currency: "usd",
      metadata: { "kind" => "compliance_report_credit", "credit_quantity" => "1" }
    )
  end

  private

  # Deliberately doesn't check unit_amount here -- if the price needs to
  # change, retire the old Stripe Price and let this create a new one
  # rather than silently drifting an existing one out from under anyone
  # who already has its id cached (e.g. a Checkout Session in progress).
  def existing_price
    @existing_price ||= Stripe::Price.list(active: true, limit: 100, expand: [ "data.product" ]).data
      .find { |price| !price.recurring && price.product.name == PRODUCT_NAME }
  end

  def product
    Stripe::Product.list(active: true, limit: 100).data.find { |p| p.name == PRODUCT_NAME } ||
      Stripe::Product.create(
        name: PRODUCT_NAME,
        description: "One additional formal Compliance Packet generation, outside any subscription plan."
      )
  end
end
