# Same idea as StripeAddonPriceSync, for a one-time paid onboarding
# service: a human (not code) personally helps a new pharmacy import their
# existing batch/vehicle records instead of them doing it themselves.
# Tagged with a distinct "kind" so StripeWebhooksController's report-credit
# granting logic doesn't mistake this purchase for a Compliance Packet
# credit -- there's nothing to grant automatically here; fulfillment is a
# real person following up after seeing the payment land in Stripe. Run
# via `bin/rails stripe:sync_white_glove_setup_price`.
class StripeWhiteGloveSetupPriceSync
  PRODUCT_NAME = "White-Glove Setup".freeze
  AMOUNT_CENTS = 29_900

  def self.call
    new.call
  end

  def call
    return existing_price if existing_price

    Stripe::Price.create(
      product: product.id, unit_amount: AMOUNT_CENTS, currency: "usd",
      metadata: { "kind" => "white_glove_setup" }
    )
  end

  private

  def existing_price
    @existing_price ||= Stripe::Price.list(active: true, limit: 100, expand: [ "data.product" ]).data
      .find { |price| !price.recurring && price.product.name == PRODUCT_NAME }
  end

  def product
    Stripe::Product.list(active: true, limit: 100).data.find { |p| p.name == PRODUCT_NAME } ||
      Stripe::Product.create(
        name: PRODUCT_NAME,
        description: "Personal, hands-on help importing your existing batch and vehicle records, instead of setting them up yourself."
      )
  end
end
