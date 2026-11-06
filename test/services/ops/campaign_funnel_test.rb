require "test_helper"

class Ops::CampaignFunnelTest < ActiveSupport::TestCase
  setup do
    @now = Time.utc(2026, 11, 6, 15)
  end

  def assessment(created_at:, **attrs)
    DscsaAssessment.build_from({}.with_indifferent_access).tap do |a|
      a.assign_attributes(created_at: created_at, **attrs)
      a.save!
    end
  end

  def funnel(window: "30") = Ops::CampaignFunnel.new(window: window, now: @now)

  test "counts each stage per source and campaign" do
    assessment(created_at: @now - 1.day, utm_source: "linkedin", utm_campaign: "first-message", email: "a@example.com", report_downloaded_at: @now)
    assessment(created_at: @now - 2.days, utm_source: "linkedin", utm_campaign: "first-message")
    CallRequest.create!(name: "Ana", email: "ana@example.com", topic: "general", utm_source: "linkedin", utm_campaign: "first-message", created_at: @now - 1.day)
    org = Organization.create!(name: "Main Street Rx", utm_source: "linkedin", utm_campaign: "first-message", created_at: @now - 1.day)
    Subscription.create!(organization: org, status: "trialing")

    row = funnel.rows.find { |r| r.label == "linkedin / first-message" }
    assert_equal [ 2, 1, 1, 1, 1, 1 ], [ row.checks, row.emails, row.pdfs, row.calls, row.signups, row.converted ]
  end

  test "unattributed records share one direct row" do
    assessment(created_at: @now - 1.day)
    CallRequest.create!(name: "Bo", email: "bo@example.com", topic: "general", created_at: @now - 1.day)

    assert_equal [ "direct" ], funnel.rows.map(&:label)
    assert_equal 1, funnel.rows.first.checks
    assert_equal 1, funnel.rows.first.calls
  end

  test "internal orgs and canceled subscriptions do not count" do
    internal = Organization.create!(name: "Demo", internal: true, utm_source: "email", created_at: @now - 1.day)
    Subscription.create!(organization: internal, status: "active")
    canceled = Organization.create!(name: "Gone Rx", utm_source: "email", created_at: @now - 1.day)
    Subscription.create!(organization: canceled, status: "canceled")

    row = funnel.rows.find { |r| r.source == "email" }
    assert_equal 1, row.signups
    assert_equal 0, row.converted
  end

  test "window limits the period and falls back to 30 days" do
    assessment(created_at: @now - 60.days, utm_source: "association")

    assert_empty funnel.rows
    assert_equal 1, funnel(window: "90").rows.sum(&:checks)
    assert_equal 1, funnel(window: "all").rows.sum(&:checks)
    assert_equal "30", funnel(window: "bogus").window
  end

  test "totals add up the rows" do
    assessment(created_at: @now - 1.day, utm_source: "email")
    assessment(created_at: @now - 1.day, utm_source: "linkedin")

    assert_equal 2, funnel.totals.checks
  end
end
