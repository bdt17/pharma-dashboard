# Same idea as StripeAddonPriceSync, for the bulk "10 Extra Compliance
# Packets" pack: 20% off buying 10 one at a time ($1,490 -> $1,192). The
# credit_quantity metadata tag is how StripeBilling/StripeWebhooksController
# know this Price should grant 10 ReportCredit rows per purchase instead of
# the usual 1. Run via `bin/rails stripe:sync_bulk_addon_prices`.
class StripeBulkAddonPriceSync
  PRODUCT_NAME = "10 Extra Compliance Packets".freeze
  CREDIT_QUANTITY = 10
  DISCOUNT = 0.20
  AMOUNT_CENTS = (StripeAddonPriceSync::AMOUNT_CENTS * CREDIT_QUANTITY * (1 - DISCOUNT)).round

  def self.call
    new.call
  end

  def call
    return existing_price if existing_price

    Stripe::Price.create(
      product: product.id, unit_amount: AMOUNT_CENTS, currency: "usd",
      metadata: { "kind" => "compliance_report_credit", "credit_quantity" => CREDIT_QUANTITY.to_s }
    )
  end

  private

  def existing_price
    @existing_price ||= Stripe::Price.list(active: true, expand: [ "data.product" ]).data
      .find { |price| !price.recurring && price.product.name == PRODUCT_NAME }
  end

  def product
    Stripe::Product.list(active: true).data.find { |p| p.name == PRODUCT_NAME } ||
      Stripe::Product.create(
        name: PRODUCT_NAME,
        description: "10 additional formal Compliance Packet generations, outside any subscription plan -- 20% off buying them one at a time."
      )
  end
end
