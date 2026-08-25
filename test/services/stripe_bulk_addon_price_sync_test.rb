require "test_helper"

class StripeBulkAddonPriceSyncTest < ActiveSupport::TestCase
  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "20% off 10 single-packet prices" do
    # 10 * $149.00 * 0.8 = $1,192.00
    assert_equal 119_200, StripeBulkAddonPriceSync::AMOUNT_CENTS
  end

  test "creates the product and price, tagged for 10 credits, when neither exists yet" do
    empty_prices = Stripe::ListObject.construct_from(data: [])
    empty_products = Stripe::ListObject.construct_from(data: [])
    fake_product = Stripe::Product.construct_from(id: "prod_bulk", name: "10 Extra Compliance Packets")
    fake_price = Stripe::Price.construct_from(id: "price_bulk", unit_amount: 119_200, currency: "usd")

    price_params = nil
    Stripe::Price.stub :list, empty_prices do
      Stripe::Product.stub :list, empty_products do
        Stripe::Product.stub :create, fake_product do
          Stripe::Price.stub :create, ->(params) { price_params = params; fake_price } do
            result = StripeBulkAddonPriceSync.call
            assert_equal fake_price, result
          end
        end
      end
    end

    assert_equal "prod_bulk", price_params[:product]
    assert_equal 119_200, price_params[:unit_amount]
    assert_equal({ "kind" => "compliance_report_credit", "credit_quantity" => "10" }, price_params[:metadata])
  end

  test "does nothing when a matching one-time price already exists" do
    existing_price = Stripe::Price.construct_from(
      id: "price_existing", unit_amount: 119_200, currency: "usd", recurring: nil,
      product: { name: "10 Extra Compliance Packets" }
    )
    prices = Stripe::ListObject.construct_from(data: [ existing_price ])

    Stripe::Price.stub :list, prices do
      Stripe::Product.stub :list, ->(*) { raise "should not need to look up the product" } do
        result = StripeBulkAddonPriceSync.call
        assert_equal existing_price, result
      end
    end
  end
end
