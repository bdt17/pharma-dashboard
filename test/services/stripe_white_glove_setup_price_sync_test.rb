require "test_helper"

class StripeWhiteGloveSetupPriceSyncTest < ActiveSupport::TestCase
  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "creates the product and price, tagged as white_glove_setup, when neither exists yet" do
    empty_prices = Stripe::ListObject.construct_from(data: [])
    empty_products = Stripe::ListObject.construct_from(data: [])
    fake_product = Stripe::Product.construct_from(id: "prod_setup", name: "White-Glove Setup")
    fake_price = Stripe::Price.construct_from(id: "price_setup", unit_amount: 29_900, currency: "usd")

    price_params = nil
    Stripe::Price.stub :list, empty_prices do
      Stripe::Product.stub :list, empty_products do
        Stripe::Product.stub :create, fake_product do
          Stripe::Price.stub :create, ->(params) { price_params = params; fake_price } do
            result = StripeWhiteGloveSetupPriceSync.call
            assert_equal fake_price, result
          end
        end
      end
    end

    assert_equal "prod_setup", price_params[:product]
    assert_equal 29_900, price_params[:unit_amount]
    assert_equal({ "kind" => "white_glove_setup" }, price_params[:metadata])
  end

  test "does nothing when a matching one-time price already exists" do
    existing_price = Stripe::Price.construct_from(
      id: "price_existing", unit_amount: 29_900, currency: "usd", recurring: nil,
      product: { name: "White-Glove Setup" }
    )
    prices = Stripe::ListObject.construct_from(data: [ existing_price ])

    Stripe::Price.stub :list, prices do
      Stripe::Product.stub :list, ->(*) { raise "should not need to look up the product" } do
        result = StripeWhiteGloveSetupPriceSync.call
        assert_equal existing_price, result
      end
    end
  end
end
