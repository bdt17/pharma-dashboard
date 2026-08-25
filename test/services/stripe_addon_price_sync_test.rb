require "test_helper"

class StripeAddonPriceSyncTest < ActiveSupport::TestCase
  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "creates the product and price when neither exists yet" do
    empty_prices = Stripe::ListObject.construct_from(data: [])
    empty_products = Stripe::ListObject.construct_from(data: [])
    fake_product = Stripe::Product.construct_from(id: "prod_addon", name: "Extra Compliance Packet")
    fake_price = Stripe::Price.construct_from(id: "price_addon", unit_amount: 14_900, currency: "usd")

    product_params = nil
    price_params = nil
    Stripe::Price.stub :list, empty_prices do
      Stripe::Product.stub :list, empty_products do
        Stripe::Product.stub :create, ->(params) { product_params = params; fake_product } do
          Stripe::Price.stub :create, ->(params) { price_params = params; fake_price } do
            result = StripeAddonPriceSync.call
            assert_equal fake_price, result
          end
        end
      end
    end

    assert_equal "Extra Compliance Packet", product_params[:name]
    assert_equal "prod_addon", price_params[:product]
    assert_equal 14_900, price_params[:unit_amount]
    assert_equal "usd", price_params[:currency]
  end

  test "reuses an existing product instead of creating a duplicate" do
    empty_prices = Stripe::ListObject.construct_from(data: [])
    existing_product = Stripe::Product.construct_from(id: "prod_existing", name: "Extra Compliance Packet")
    products = Stripe::ListObject.construct_from(data: [ existing_product ])
    fake_price = Stripe::Price.construct_from(id: "price_addon", unit_amount: 14_900, currency: "usd")

    price_params = nil
    Stripe::Price.stub :list, empty_prices do
      Stripe::Product.stub :list, products do
        Stripe::Product.stub :create, ->(*) { raise "should not create a second product" } do
          Stripe::Price.stub :create, ->(params) { price_params = params; fake_price } do
            StripeAddonPriceSync.call
          end
        end
      end
    end

    assert_equal "prod_existing", price_params[:product]
  end

  test "does nothing when a matching one-time price already exists" do
    existing_price = Stripe::Price.construct_from(
      id: "price_existing", unit_amount: 14_900, currency: "usd", recurring: nil,
      product: { name: "Extra Compliance Packet" }
    )
    prices = Stripe::ListObject.construct_from(data: [ existing_price ])

    Stripe::Price.stub :list, prices do
      Stripe::Product.stub :list, ->(*) { raise "should not need to look up the product" } do
        result = StripeAddonPriceSync.call
        assert_equal existing_price, result
      end
    end
  end
end
