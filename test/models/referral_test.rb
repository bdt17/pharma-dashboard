require "test_helper"

class ReferralTest < ActiveSupport::TestCase
  setup do
    @referrer = Organization.create!(name: "Referring Pharmacy")
    @referred = Organization.create!(name: "New Pharmacy")
  end

  test "can be created with a referrer and referred organization" do
    referral = Referral.create!(referrer_organization: @referrer, referred_organization: @referred)
    assert_nil referral.rewarded_at
  end

  test "an organization can only ever be the referred side once" do
    Referral.create!(referrer_organization: @referrer, referred_organization: @referred)
    other_referrer = Organization.create!(name: "Another Pharmacy")

    duplicate = Referral.new(referrer_organization: other_referrer, referred_organization: @referred)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:referred_organization_id], "has already been taken"
  end

  test "pending scope excludes already-rewarded referrals" do
    rewarded = Referral.create!(referrer_organization: @referrer, referred_organization: @referred, rewarded_at: Time.current)
    other_referred = Organization.create!(name: "Third Pharmacy")
    pending = Referral.create!(referrer_organization: @referrer, referred_organization: other_referred)

    assert_equal [ pending ], Referral.pending
    assert_not_includes Referral.pending, rewarded
  end
end
