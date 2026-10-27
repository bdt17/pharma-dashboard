require "test_helper"

class Ops::WeeklyDigestTest < ActiveSupport::TestCase
  setup do
    @now = Time.utc(2026, 11, 2, 15)
    @customer = Organization.create!(name: "Main Street Rx", created_at: @now - 2.days)
    @internal = Organization.create!(name: "Demo Org", internal: true, created_at: @now - 1.day)
    @old = Organization.create!(name: "Old Rx", created_at: @now - 30.days)
  end

  def digest = Ops::WeeklyDigest.new(now: @now)

  test "counts only this week's leads and checks" do
    CallRequest.create!(name: "Ana", email: "ana@example.com", topic: "general", created_at: @now - 1.day)
    CallRequest.create!(name: "Old", email: "old@example.com", topic: "general", created_at: @now - 10.days)
    DscsaAssessment.build_from({ "custody" => "no", email: "a@example.com" }.with_indifferent_access).tap { |a| a.created_at = @now - 3.days }.save!
    DscsaAssessment.build_from({}.with_indifferent_access).tap { |a| a.created_at = @now - 20.days }.save!

    assert_equal [ "Ana" ], digest.new_leads.map(&:name)
    assert_equal 2, digest.unhandled_leads_count
    assert_equal 1, digest.assessments_count
    assert_equal 1, digest.assessments_with_email_count
  end

  test "signups and subscriptions exclude internal orgs" do
    Subscription.create!(organization: @customer, status: "trialing", created_at: @now - 1.day)
    Subscription.create!(organization: @internal, status: "active", created_at: @now - 1.day)
    Subscription.create!(organization: @old, status: "active", created_at: @now - 25.days)

    assert_equal [ "Main Street Rx" ], digest.new_organizations.map(&:name)
    assert_equal [ "Main Street Rx" ], digest.subscriptions_started.map { |s| s.organization.name }
    assert_equal 1, digest.trialing_count
    assert_equal 1, digest.active_count
  end

  test "headline names leads, new subscriptions, and owed setups" do
    @customer.update!(free_setup_owed_at: @now - 1.day)
    assert_equal "0 leads, 0 new subscriptions, 1 setup owed", digest.headline
  end
end
