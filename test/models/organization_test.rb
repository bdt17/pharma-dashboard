require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "requires a name" do
    org = Organization.new
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "cannot be destroyed while it still has users" do
    org = Organization.create!(name: "Acme Pharma")
    User.create!(email: "keeper@example.com", password: "password123!", organization: org, role: "admin")

    assert_not org.destroy
    assert_includes org.errors[:base].join, "Cannot delete record"
  end

  test "is assigned a unique referral code on creation" do
    org = Organization.create!(name: "Acme Pharma")
    assert_match(/\A[A-Z0-9]{8}\z/, org.referral_code)
  end

  test "does not overwrite an explicitly set referral code" do
    org = Organization.create!(name: "Acme Pharma", referral_code: "MYCODE1")
    assert_equal "MYCODE1", org.referral_code
  end

  test "find_by_referral_code matches case-insensitively" do
    org = Organization.create!(name: "Acme Pharma", referral_code: "ABC123XY")
    assert_equal org, Organization.find_by_referral_code("abc123xy")
    assert_equal org, Organization.find_by_referral_code(" ABC123XY ")
  end

  test "find_by_referral_code returns nil for a blank or unknown code" do
    assert_nil Organization.find_by_referral_code(nil)
    assert_nil Organization.find_by_referral_code("")
    assert_nil Organization.find_by_referral_code("NOPE0000")
  end

  test "is assigned a unique verification_token on creation" do
    org = Organization.create!(name: "Acme Pharma")
    assert org.verification_token.present?
  end

  test "does not overwrite an explicitly set verification_token" do
    org = Organization.create!(name: "Acme Pharma", verification_token: "my-custom-token")
    assert_equal "my-custom-token", org.verification_token
  end

  test "verified? is false with no subscription" do
    org = Organization.create!(name: "Acme Pharma")
    assert_not org.verified?
  end

  test "verified? is true with an active or trialing subscription" do
    org = Organization.create!(name: "Acme Pharma")
    Subscription.create!(organization: org, status: "trialing", stripe_subscription_id: "sub_123")
    assert org.verified?
  end

  test "verified? is false once the subscription is canceled" do
    org = Organization.create!(name: "Acme Pharma")
    Subscription.create!(organization: org, status: "canceled", stripe_subscription_id: "sub_123")
    assert_not org.verified?
  end
end
