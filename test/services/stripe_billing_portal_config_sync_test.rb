require "test_helper"

class StripeBillingPortalConfigSyncTest < ActiveSupport::TestCase
  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
  end

  teardown do
    Stripe.api_key = @previous_key
  end

  test "creates a configuration when no default one exists yet" do
    empty_list = Stripe::ListObject.construct_from(data: [])
    fake_config = Stripe::BillingPortal::Configuration.construct_from(id: "bpc_new")

    create_params = nil
    Stripe::BillingPortal::Configuration.stub :list, empty_list do
      Stripe::BillingPortal::Configuration.stub :create, ->(params) { create_params = params; fake_config } do
        result = StripeBillingPortalConfigSync.call
        assert_equal fake_config, result
      end
    end

    assert create_params[:features][:invoice_history][:enabled]
    assert create_params[:features][:payment_method_update][:enabled]
    assert create_params[:features][:subscription_cancel][:enabled]
  end

  test "reuses the existing default configuration instead of creating a duplicate" do
    non_default = Stripe::BillingPortal::Configuration.construct_from(id: "bpc_other", is_default: false)
    default_config = Stripe::BillingPortal::Configuration.construct_from(id: "bpc_default", is_default: true)
    list = Stripe::ListObject.construct_from(data: [ non_default, default_config ])

    Stripe::BillingPortal::Configuration.stub :list, list do
      Stripe::BillingPortal::Configuration.stub :create, ->(*) { raise "should not create a second configuration" } do
        result = StripeBillingPortalConfigSync.call
        assert_equal default_config, result
      end
    end
  end

  test "creates a new configuration if the only active ones aren't the default" do
    non_default = Stripe::BillingPortal::Configuration.construct_from(id: "bpc_other", is_default: false)
    list = Stripe::ListObject.construct_from(data: [ non_default ])
    fake_config = Stripe::BillingPortal::Configuration.construct_from(id: "bpc_new")

    Stripe::BillingPortal::Configuration.stub :list, list do
      Stripe::BillingPortal::Configuration.stub :create, fake_config do
        result = StripeBillingPortalConfigSync.call
        assert_equal fake_config, result
      end
    end
  end
end
