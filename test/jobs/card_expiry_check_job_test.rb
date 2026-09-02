require "test_helper"

class CardExpiryCheckJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @previous_key = Stripe.api_key
    Stripe.api_key = "sk_test_fake"
    @organization = Organization.create!(name: "Acme Pharma", stripe_customer_id: "cus_1")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_1")
  end

  teardown { Stripe.api_key = @previous_key }

  def with_card(card, &block)
    StripeBilling.stub(:default_card_for, ->(_org) { card }, &block)
  end

  # Expires at the end of the current month -- inside the 45-day window.
  def soon
    d = Date.current
    { last4: "4242", exp_month: d.month, exp_year: d.year }
  end

  # Already lapsed -- also "expiring soon", but a different period.
  def already_expired
    d = 3.months.ago.to_date
    { last4: "1111", exp_month: d.month, exp_year: d.year }
  end

  def far
    { last4: "4242", exp_month: 1, exp_year: Date.current.year + 5 }
  end

  test "emails the admins once when the card expires within the lead time" do
    with_card(soon) do
      assert_enqueued_email_with SubscriptionMailer, :card_expiring, args: [ @organization, soon ] do
        CardExpiryCheckJob.perform_now
      end
    end

    period = format("%04d-%02d", soon[:exp_year], soon[:exp_month])
    assert_equal period, @organization.reload.card_expiry_notified_for
  end

  test "does not email again for the same card on a later run" do
    with_card(soon) do
      CardExpiryCheckJob.perform_now
      assert_no_enqueued_emails { CardExpiryCheckJob.perform_now }
    end
  end

  test "emails again once the card is replaced with a different expiry" do
    with_card(soon) { CardExpiryCheckJob.perform_now }

    with_card(already_expired) do
      assert_enqueued_emails 1 do
        CardExpiryCheckJob.perform_now
      end
    end
  end

  test "ignores a card that is not expiring soon" do
    with_card(far) do
      assert_no_enqueued_emails { CardExpiryCheckJob.perform_now }
    end
    assert_nil @organization.reload.card_expiry_notified_for
  end

  test "skips an organization with no active subscription" do
    @organization.subscriptions.update_all(status: "canceled")
    with_card(soon) do
      assert_no_enqueued_emails { CardExpiryCheckJob.perform_now }
    end
  end

  test "skips when Stripe returns no card" do
    with_card(nil) do
      assert_no_enqueued_emails { CardExpiryCheckJob.perform_now }
    end
  end

  test "does nothing when Stripe is not configured" do
    Stripe.api_key = nil
    StripeBilling.stub(:default_card_for, ->(_) { flunk "should not reach Stripe" }) do
      assert_no_enqueued_emails { CardExpiryCheckJob.perform_now }
    end
  end
end
