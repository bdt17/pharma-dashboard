require "test_helper"

class StripeSubscriptionPlansSyncTest < ActiveSupport::TestCase
  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "creates a product and monthly price for every tier when none exist" do
    empty = Stripe::ListObject.construct_from(data: [])
    created_products = []
    created_prices = []

    Stripe::Product.stub :list, empty do
      Stripe::Price.stub :list, empty do
        Stripe::Product.stub :create, ->(params) {
          created_products << params
          Stripe::Product.construct_from(id: "prod_#{params[:metadata][:tier]}", name: params[:name])
        } do
          Stripe::Price.stub :create, ->(params) {
            created_prices << params
            Stripe::Price.construct_from(id: "price_#{params[:metadata][:tier]}", unit_amount: params[:unit_amount], currency: "usd")
          } do
            result = StripeSubscriptionPlansSync.call
            assert_equal 4, result.created.size
            assert_empty result.existing
          end
        end
      end
    end

    assert_equal %w[Starter Pro Compliance Enterprise], created_products.map { |p| p[:name] }
    assert_equal [ 9_900, 24_900, 49_900, 149_900 ], created_prices.map { |p| p[:unit_amount] }
    assert created_prices.all? { |p| p[:recurring] == { interval: "month" } }
    assert_equal "15", created_prices.first[:metadata]["packet_allowance"]
    assert_equal "unlimited", created_prices.last[:metadata]["packet_allowance"]
  end

  test "reuses existing products and skips tiers that already have a monthly price" do
    starter_product = Stripe::Product.construct_from(id: "prod_starter", name: "Starter")
    starter_price = Stripe::Price.construct_from(id: "price_starter", product: "prod_starter", recurring: { interval: "month" })

    Stripe::Product.stub :list, Stripe::ListObject.construct_from(data: [ starter_product ]) do
      Stripe::Price.stub :list, Stripe::ListObject.construct_from(data: [ starter_price ]) do
        Stripe::Product.stub :create, ->(params) { Stripe::Product.construct_from(id: "prod_new", name: params[:name]) } do
          Stripe::Price.stub :create, ->(params) { Stripe::Price.construct_from(id: "price_new", unit_amount: params[:unit_amount]) } do
            result = StripeSubscriptionPlansSync.call
            assert_equal [ starter_price ], result.existing
            assert_equal 3, result.created.size
          end
        end
      end
    end
  end
end
