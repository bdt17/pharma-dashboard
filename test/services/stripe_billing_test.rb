require "test_helper"

class StripeBillingTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @previous_key = Stripe.api_key
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "configured? is false without an api key, true with one" do
    Stripe.api_key = nil
    assert_not StripeBilling.configured?

    Stripe.api_key = "sk_test_fake"
    assert StripeBilling.configured?
  end

  test "available_plans returns [] when Stripe isn't configured, without calling the API" do
    Stripe.api_key = nil
    Stripe::Price.stub :list, ->(*) { raise "should not call the Stripe API" } do
      assert_equal [], StripeBilling.available_plans
    end
  end

  test "available_plans maps real Stripe::Price data into a plain hash" do
    Stripe.api_key = "sk_test_fake"
    price = Stripe::Price.construct_from(
      id: "price_123",
      unit_amount: 9900,
      currency: "usd",
      recurring: { interval: "month" },
      product: { name: "Starter" }
    )
    list = Stripe::ListObject.construct_from(data: [ price ])

    Stripe::Price.stub :list, list do
      plans = StripeBilling.available_plans
      assert_equal [ { id: "price_123", product_name: "Starter", amount: 99.0, currency: "usd", interval: "month" } ], plans
    end
  end

  test "start_checkout! raises NotConfigured rather than hitting the API with no key" do
    Stripe.api_key = nil
    assert_raises(StripeBilling::NotConfigured) do
      StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
    end
  end

  test "start_checkout! creates a Stripe customer for an organization that doesn't have one yet" do
    Stripe.api_key = "sk_test_fake"
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    Stripe::Customer.stub :create, fake_customer do
      Stripe::Checkout::Session.stub :create, fake_session do
        url = StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
        assert_equal "https://checkout.stripe.com/cs_123", url
      end
    end

    assert_equal "cus_new", @organization.reload.stripe_customer_id
  end

  test "start_checkout! reuses an existing Stripe customer instead of creating a new one" do
    Stripe.api_key = "sk_test_fake"
    @organization.update!(stripe_customer_id: "cus_existing")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    Stripe::Customer.stub :create, ->(*) { raise "should not create a new customer" } do
      Stripe::Checkout::Session.stub :create, ->(params) {
        assert_equal "cus_existing", params[:customer]
        fake_session
      } do
        StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
      end
    end
  end
end
