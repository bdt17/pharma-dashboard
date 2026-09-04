require "test_helper"

class StripeAnnualPriceSyncTest < ActiveSupport::TestCase
  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  def monthly_price(product_id: "prod_123", unit_amount: 9900, tier: "starter")
    Stripe::Price.construct_from(
      id: "price_month",
      unit_amount: unit_amount,
      currency: "usd",
      recurring: { interval: "month" },
      product: { id: product_id, name: "Starter" },
      metadata: tier ? { "tier" => tier } : {}
    )
  end

  test "creates an annual price at 10% off 12 months when none exists yet" do
    monthly_list = Stripe::ListObject.construct_from(data: [ monthly_price ])
    empty_list = Stripe::ListObject.construct_from(data: [])
    created_price = Stripe::Price.construct_from(id: "price_year", unit_amount: 106_920, currency: "usd")

    creation_params = nil
    Stripe::Price.stub :list, ->(params) { params[:recurring][:interval] == "month" ? monthly_list : empty_list } do
      Stripe::Price.stub :create, ->(params) { creation_params = params; created_price } do
        result = StripeAnnualPriceSync.call
        assert_equal [ created_price ], result.created
      end
    end

    assert_equal "prod_123", creation_params[:product]
    # $99/month * 12 * 0.9 = $1069.20 -> 106920 cents
    assert_equal 106_920, creation_params[:unit_amount]
    assert_equal({ interval: "year" }, creation_params[:recurring])
    assert_equal({ "tier" => "starter" }, creation_params[:metadata])
  end

  test "leaves the annual price untagged when the monthly price has no tier" do
    monthly_list = Stripe::ListObject.construct_from(data: [ monthly_price(tier: nil) ])
    empty_list = Stripe::ListObject.construct_from(data: [])
    created_price = Stripe::Price.construct_from(id: "price_year")

    creation_params = nil
    Stripe::Price.stub :list, ->(params) { params[:recurring][:interval] == "month" ? monthly_list : empty_list } do
      Stripe::Price.stub :create, ->(params) { creation_params = params; created_price } do
        StripeAnnualPriceSync.call
      end
    end

    assert_equal({}, creation_params[:metadata])
  end

  test "does not create a duplicate annual price when one already exists for the product" do
    monthly_list = Stripe::ListObject.construct_from(data: [ monthly_price ])
    existing_annual = Stripe::ListObject.construct_from(data: [ Stripe::Price.construct_from(id: "price_year_existing") ])

    Stripe::Price.stub :list, ->(params) { params[:recurring] && params[:recurring][:interval] == "month" ? monthly_list : existing_annual } do
      Stripe::Price.stub :create, ->(*) { raise "should not create a second annual price" } do
        result = StripeAnnualPriceSync.call
        assert_equal [], result.created
      end
    end
  end
end
