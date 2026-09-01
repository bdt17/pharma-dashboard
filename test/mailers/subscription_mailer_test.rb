require "test_helper"

class SubscriptionMailerTest < ActionMailer::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @pharmacist = User.create!(email: "rx@example.com", password: "password123!", organization: @organization, role: "pharmacist")
    @subscription = Subscription.create!(organization: @organization, stripe_subscription_id: "sub_1", status: "past_due")
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
