require "test_helper"

class StripeBillingTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @previous_key = Stripe.api_key
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  # start_checkout! now looks up the price's interval (to decide whether
  # the founding-customer offer applies) before ever touching the
  # customer/session machinery these older tests are actually about --
  # stub it to a plain monthly price so they don't need to know that.
  def stub_monthly_price(id: "price_123", &block)
    fake_price = Stripe::Price.construct_from(id: id, recurring: { interval: "month" })
    Stripe::Price.stub(:retrieve, fake_price, &block)
  end

  test "add_packet_overage_item! creates a pending invoice item priced off the single-packet Price" do
    Stripe.api_key = "sk_test_fake"
    @organization.update!(stripe_customer_id: "cus_1")
    packet_price = Stripe::Price.construct_from(id: "price_pkt", unit_amount: 14_900, currency: "usd", product: { name: "Extra Compliance Packet" })
    list = Stripe::ListObject.construct_from(data: [ packet_price ])
    created = nil

    Stripe::Price.stub :list, list do
      Stripe::InvoiceItem.stub :create, ->(params) { created = params; Stripe::InvoiceItem.construct_from(id: "ii_1") } do
        result = StripeBilling.add_packet_overage_item!(organization: @organization, description: "Extra packet — LOT-1")

        assert_equal({ invoice_item_id: "ii_1", amount_cents: 14_900, currency: "usd" }, result)
        assert_equal "cus_1", created[:customer]
        assert_equal "price_pkt", created[:price]
        assert_nil created[:invoice], "must be a pending item, not attached to an invoice"
      end
    end
  end

  test "add_packet_overage_item! raises NotConfigured without a key, a customer, or the Price" do
    Stripe.api_key = nil
    assert_raises(StripeBilling::NotConfigured) { StripeBilling.add_packet_overage_item!(organization: @organization, description: "x") }

    Stripe.api_key = "sk_test_fake"
    assert_raises(StripeBilling::NotConfigured) { StripeBilling.add_packet_overage_item!(organization: @organization, description: "x") }

    @organization.update!(stripe_customer_id: "cus_1")
    Stripe::Price.stub :list, Stripe::ListObject.construct_from(data: []) do
      assert_raises(StripeBilling::NotConfigured) { StripeBilling.add_packet_overage_item!(organization: @organization, description: "x") }
    end
  end

  test "default_card_for returns the customer's default card" do
    Stripe.api_key = "sk_test_fake"
    @organization.update!(stripe_customer_id: "cus_1")
    pm = Stripe::PaymentMethod.construct_from(card: { last4: "4242", exp_month: 8, exp_year: 2027 })
    customer = Stripe::Customer.construct_from(invoice_settings: { default_payment_method: pm })

    Stripe::Customer.stub :retrieve, customer do
      assert_equal({ last4: "4242", exp_month: 8, exp_year: 2027 }, StripeBilling.default_card_for(@organization))
    end
  end

  test "default_card_for falls back to the first saved card when there's no default" do
    Stripe.api_key = "sk_test_fake"
    @organization.update!(stripe_customer_id: "cus_1")
    customer = Stripe::Customer.construct_from(invoice_settings: { default_payment_method: nil })
    pm = Stripe::PaymentMethod.construct_from(card: { last4: "1881", exp_month: 1, exp_year: 2026 })

    Stripe::Customer.stub :retrieve, customer do
      Stripe::PaymentMethod.stub :list, Stripe::ListObject.construct_from(data: [ pm ]) do
        assert_equal({ last4: "1881", exp_month: 1, exp_year: 2026 }, StripeBilling.default_card_for(@organization))
      end
    end
  end

  test "default_card_for returns nil without a customer, or on a Stripe error" do
    Stripe.api_key = "sk_test_fake"
    assert_nil StripeBilling.default_card_for(@organization)

    @organization.update!(stripe_customer_id: "cus_1")
    Stripe::Customer.stub :retrieve, ->(*) { raise Stripe::InvalidRequestError.new("no such customer", "id") } do
      assert_nil StripeBilling.default_card_for(@organization)
    end
  end

  test "default_card_for raises NotConfigured without an API key" do
    Stripe.api_key = nil
    assert_raises(StripeBilling::NotConfigured) { StripeBilling.default_card_for(@organization) }
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
      metadata: { "tier" => "starter" },
      product: { name: "Starter" }
    )
    list = Stripe::ListObject.construct_from(data: [ price ])

    Stripe::Price.stub :list, list do
      plans = StripeBilling.available_plans
      assert_equal [ { id: "price_123", product_name: "Starter", amount: 99.0, currency: "usd", interval: "month", tier: "starter" } ], plans
    end
  end

  test "available_plans excludes one-time (non-recurring) prices, e.g. the addons" do
    Stripe.api_key = "sk_test_fake"
    recurring = Stripe::Price.construct_from(
      id: "price_sub", unit_amount: 9900, currency: "usd", recurring: { interval: "month" }, product: { name: "Starter" }
    )
    one_time = Stripe::Price.construct_from(
      id: "price_addon", unit_amount: 14_900, currency: "usd", recurring: nil, product: { name: "Extra Compliance Packet" }
    )
    list = Stripe::ListObject.construct_from(data: [ recurring, one_time ])

    Stripe::Price.stub :list, list do
      plans = StripeBilling.available_plans
      assert_equal [ "price_sub" ], plans.map { |p| p[:id] }
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

    stub_monthly_price do
      Stripe::Customer.stub :create, fake_customer do
        Stripe::Checkout::Session.stub :create, fake_session do
          url = StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
          assert_equal "https://checkout.stripe.com/cs_123", url
        end
      end
    end

    assert_equal "cus_new", @organization.reload.stripe_customer_id
  end

  test "start_checkout! reuses an existing Stripe customer instead of creating a new one" do
    Stripe.api_key = "sk_test_fake"
    @organization.update!(stripe_customer_id: "cus_existing")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    stub_monthly_price do
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

  test "start_checkout! recreates the customer and retries when the stored customer id is stale" do
    Stripe.api_key = "sk_test_fake"
    @organization.update!(stripe_customer_id: "cus_stale")
    fake_new_customer = Stripe::Customer.construct_from(id: "cus_fresh")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")
    stale_customer_error = Stripe::InvalidRequestError.new("No such customer: 'cus_stale'", "customer", code: "resource_missing")

    attempts = []
    stub_monthly_price do
      Stripe::Customer.stub :create, fake_new_customer do
        Stripe::Checkout::Session.stub :create, ->(params) {
          attempts << params[:customer]
          raise stale_customer_error if params[:customer] == "cus_stale"

          fake_session
        } do
          url = StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
          assert_equal "https://checkout.stripe.com/cs_123", url
        end
      end
    end

    assert_equal [ "cus_stale", "cus_fresh" ], attempts
    assert_equal "cus_fresh", @organization.reload.stripe_customer_id
  end

  test "start_checkout! re-raises a Stripe error that isn't a stale customer" do
    Stripe.api_key = "sk_test_fake"
    @organization.update!(stripe_customer_id: "cus_existing")
    other_error = Stripe::InvalidRequestError.new("No such price: 'price_123'", "price", code: "resource_missing")

    stub_monthly_price do
      Stripe::Checkout::Session.stub :create, ->(*) { raise other_error } do
        assert_raises(Stripe::InvalidRequestError) do
          StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
        end
      end
    end
  end

  test "available_addons lists only non-recurring prices" do
    Stripe.api_key = "sk_test_fake"
    recurring = Stripe::Price.construct_from(
      id: "price_sub", unit_amount: 9900, currency: "usd", recurring: { interval: "month" }, product: { name: "Starter" }
    )
    one_time = Stripe::Price.construct_from(
      id: "price_addon", unit_amount: 14_900, currency: "usd", recurring: nil, product: { name: "Extra Compliance Packet" }
    )
    list = Stripe::ListObject.construct_from(data: [ recurring, one_time ])

    Stripe::Price.stub :list, list do
      addons = StripeBilling.available_addons
      assert_equal [ { id: "price_addon", product_name: "Extra Compliance Packet", amount: 149.0, currency: "usd" } ], addons
    end
  end

  test "available_addons returns [] when Stripe isn't configured" do
    Stripe.api_key = nil
    assert_equal [], StripeBilling.available_addons
  end

  test "start_addon_checkout! creates a one-time payment Checkout Session, defaulting to a single report credit for an untagged price" do
    Stripe.api_key = "sk_test_fake"
    fake_price = Stripe::Price.construct_from(id: "price_addon", unit_amount: 14_900, currency: "usd", metadata: {})
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    session_params = nil
    Stripe::Price.stub :retrieve, fake_price do
      Stripe::Customer.stub :create, fake_customer do
        Stripe::Checkout::Session.stub :create, ->(params) { session_params = params; fake_session } do
          url = StripeBilling.start_addon_checkout!(organization: @organization, price_id: "price_addon", success_url: "https://x/success", cancel_url: "https://x/cancel")
          assert_equal "https://checkout.stripe.com/cs_123", url
        end
      end
    end

    assert_equal "payment", session_params[:mode]
    assert_equal({ "kind" => "compliance_report_credit", "credit_quantity" => "1" }, session_params[:metadata])
  end

  test "start_addon_checkout! passes through a bulk price's credit_quantity metadata" do
    Stripe.api_key = "sk_test_fake"
    fake_price = Stripe::Price.construct_from(
      id: "price_bulk", unit_amount: 119_200, currency: "usd",
      metadata: { "kind" => "compliance_report_credit", "credit_quantity" => "10" }
    )
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    session_params = nil
    Stripe::Price.stub :retrieve, fake_price do
      Stripe::Customer.stub :create, fake_customer do
        Stripe::Checkout::Session.stub :create, ->(params) { session_params = params; fake_session } do
          StripeBilling.start_addon_checkout!(organization: @organization, price_id: "price_bulk", success_url: "https://x/success", cancel_url: "https://x/cancel")
        end
      end
    end

    assert_equal({ "kind" => "compliance_report_credit", "credit_quantity" => "10" }, session_params[:metadata])
  end

  test "start_addon_checkout! does not tag a non-credit addon (e.g. White-Glove Setup) with credit_quantity" do
    Stripe.api_key = "sk_test_fake"
    fake_price = Stripe::Price.construct_from(id: "price_setup", unit_amount: 29_900, currency: "usd", metadata: { "kind" => "white_glove_setup" })
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    session_params = nil
    Stripe::Price.stub :retrieve, fake_price do
      Stripe::Customer.stub :create, fake_customer do
        Stripe::Checkout::Session.stub :create, ->(params) { session_params = params; fake_session } do
          StripeBilling.start_addon_checkout!(organization: @organization, price_id: "price_setup", success_url: "https://x/success", cancel_url: "https://x/cancel")
        end
      end
    end

    assert_equal({ "kind" => "white_glove_setup" }, session_params[:metadata])
  end

  test "start_addon_checkout! raises NotConfigured rather than hitting the API with no key" do
    Stripe.api_key = nil
    assert_raises(StripeBilling::NotConfigured) do
      StripeBilling.start_addon_checkout!(organization: @organization, price_id: "price_addon", success_url: "https://x/success", cancel_url: "https://x/cancel")
    end
  end

  test "start_checkout! includes a 14-day trial on the subscription" do
    Stripe.api_key = "sk_test_fake"
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    session_params = nil
    stub_monthly_price do
      Stripe::Customer.stub :create, fake_customer do
        Stripe::Checkout::Session.stub :create, ->(params) { session_params = params; fake_session } do
          StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
        end
      end
    end

    assert_equal({ trial_period_days: 14 }, session_params[:subscription_data])
  end

  test "start_checkout! applies the founding-customer coupon to a monthly plan before the cutoff" do
    Stripe.api_key = "sk_test_fake"
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    session_params = nil
    travel_to StripeBilling.founding_offer_cutoff - 1.day do
      stub_monthly_price do
        Stripe::Customer.stub :create, fake_customer do
          Stripe::Checkout::Session.stub :create, ->(params) { session_params = params; fake_session } do
            StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
          end
        end
      end
    end

    assert_equal [ { coupon: StripeBilling::FOUNDING_OFFER_COUPON_ID } ], session_params[:discounts]
  end

  test "start_checkout! does not apply the founding-customer coupon to an annual plan" do
    Stripe.api_key = "sk_test_fake"
    fake_price = Stripe::Price.construct_from(id: "price_annual", recurring: { interval: "year" })
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    session_params = nil
    travel_to StripeBilling.founding_offer_cutoff - 1.day do
      Stripe::Price.stub :retrieve, fake_price do
        Stripe::Customer.stub :create, fake_customer do
          Stripe::Checkout::Session.stub :create, ->(params) { session_params = params; fake_session } do
            StripeBilling.start_checkout!(organization: @organization, price_id: "price_annual", success_url: "https://x/success", cancel_url: "https://x/cancel")
          end
        end
      end
    end

    assert_nil session_params[:discounts]
  end

  test "start_checkout! does not apply the founding-customer coupon after the cutoff, and never even looks up the price" do
    Stripe.api_key = "sk_test_fake"
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    session_params = nil
    travel_to StripeBilling.founding_offer_cutoff + 1.day do
      Stripe::Price.stub :retrieve, ->(*) { raise "should not look up the price once the offer window is closed" } do
        Stripe::Customer.stub :create, fake_customer do
          Stripe::Checkout::Session.stub :create, ->(params) { session_params = params; fake_session } do
            StripeBilling.start_checkout!(organization: @organization, price_id: "price_123", success_url: "https://x/success", cancel_url: "https://x/cancel")
          end
        end
      end
    end

    assert_nil session_params[:discounts]
  end

  test "start_addon_checkout! does not include trial subscription_data (it's a one-time payment)" do
    Stripe.api_key = "sk_test_fake"
    fake_price = Stripe::Price.construct_from(id: "price_addon", unit_amount: 14_900, currency: "usd", metadata: {})
    fake_customer = Stripe::Customer.construct_from(id: "cus_new")
    fake_session = Stripe::Checkout::Session.construct_from(id: "cs_123", url: "https://checkout.stripe.com/cs_123")

    session_params = nil
    Stripe::Price.stub :retrieve, fake_price do
      Stripe::Customer.stub :create, fake_customer do
        Stripe::Checkout::Session.stub :create, ->(params) { session_params = params; fake_session } do
          StripeBilling.start_addon_checkout!(organization: @organization, price_id: "price_addon", success_url: "https://x/success", cancel_url: "https://x/cancel")
        end
      end
    end

    assert_nil session_params[:subscription_data]
  end

  test "billing_portal_url creates a Billing Portal session for the organization's Stripe customer" do
    Stripe.api_key = "sk_test_fake"
    @organization.update!(stripe_customer_id: "cus_existing")
    fake_portal_session = Stripe::BillingPortal::Session.construct_from(id: "bps_123", url: "https://billing.stripe.com/session/bps_123")

    session_params = nil
    Stripe::BillingPortal::Session.stub :create, ->(params) { session_params = params; fake_portal_session } do
      url = StripeBilling.billing_portal_url(organization: @organization, return_url: "https://x/billing")
      assert_equal "https://billing.stripe.com/session/bps_123", url
    end

    assert_equal "cus_existing", session_params[:customer]
    assert_equal "https://x/billing", session_params[:return_url]
  end

  test "billing_portal_url raises NotConfigured rather than hitting the API with no key" do
    Stripe.api_key = nil
    @organization.update!(stripe_customer_id: "cus_existing")

    assert_raises(StripeBilling::NotConfigured) do
      StripeBilling.billing_portal_url(organization: @organization, return_url: "https://x/billing")
    end
  end

  test "billing_portal_url raises for an organization with no Stripe customer yet" do
    Stripe.api_key = "sk_test_fake"
    assert_nil @organization.stripe_customer_id

    assert_raises(ArgumentError) do
      StripeBilling.billing_portal_url(organization: @organization, return_url: "https://x/billing")
    end
  end
end
