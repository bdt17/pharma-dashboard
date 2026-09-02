require "test_helper"

class SubscriptionMailerTest < ActionMailer::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @pharmacist = User.create!(email: "rx@example.com", password: "password123!", organization: @organization, role: "pharmacist")
    @subscription = Subscription.create!(organization: @organization, stripe_subscription_id: "sub_1", status: "past_due")
  end

  test "includes the plan, amount, and billing-period end when known" do
    @subscription.update!(tier: "pro", plan_amount: 249, current_period_end: 10.days.from_now)
    mail = SubscriptionMailer.payment_failed(@subscription)

    [ mail.html_part, mail.text_part ].each do |part|
      body = part.body.encoded
      assert_match "Pro", body
      assert_match "$249.00", body
      assert_match 10.days.from_now.strftime("%B %-d, %Y"), body
    end
  end

  test "omits the billing-period end once it has passed" do
    @subscription.update!(tier: "pro", plan_amount: 249, current_period_end: 2.days.ago)
    mail = SubscriptionMailer.payment_failed(@subscription)

    refute_match "Billing period ends", mail.html_part.body.encoded
  end

  test "renders without a tier, amount, or period end" do
    mail = SubscriptionMailer.payment_failed(@subscription)

    assert_match "Acme Pharma", mail.body.encoded
    refute_match "Amount due", mail.body.encoded
  end

  test "payment_failed goes to admins only and links to billing" do
    mail = SubscriptionMailer.payment_failed(@subscription)

    assert_equal [ "admin@example.com" ], mail.to
    assert_match "didn't go through", mail.subject

    body = mail.body.encoded
    assert_match "Acme Pharma", body
    assert_match "/billing", body
  end

  test "falls back to the sender address when the org has no admin" do
    @admin.destroy
    mail = SubscriptionMailer.payment_failed(@subscription.reload)

    assert_equal [ SubscriptionMailer.default[:from] ], mail.to
  end
end
