require "test_helper"

# Every deadline-dependent page switches tense on its own the day after the
# DSCSA exemption ends. Pinned to fixed dates so these keep passing after
# the real deadline goes by.
class DscsaDeadlineCopyTest < ActionDispatch::IntegrationTest
  BEFORE = Time.utc(2026, 11, 1, 15)
  AFTER = Time.utc(2026, 11, 29, 15)

  test "the DSCSA landing page" do
    travel_to(BEFORE) { get dscsa_2026_path }
    assert_match "Is your pharmacy ready for the DSCSA deadline?", response.body
    assert_match "DSCSA deadline offer", response.body

    travel_to(AFTER) { get dscsa_2026_path }
    assert_match "The DSCSA exemption has ended", response.body
    assert_no_match "ready for the DSCSA deadline?", response.body
    assert_no_match "DSCSA deadline offer", response.body
  end

  test "the home page callout" do
    travel_to(BEFORE) { get root_path }
    assert_match "preparation needs to be finished", response.body

    travel_to(AFTER) { get root_path }
    assert_match "the requirements apply to you now", response.body
  end

  test "the assessment intro" do
    travel_to(AFTER) { get dscsa_assessment_path }
    assert_match "now that the small-dispenser exemption has ended", response.body
  end

  test "the blog post gets an update note only after the date" do
    travel_to(BEFORE) { get blog_dscsa_exemption_2026_path }
    assert_no_match "this date has now passed", response.body

    travel_to(AFTER) { get blog_dscsa_exemption_2026_path }
    assert_match "this date has now passed", response.body
  end

  test "the pricing page shows the deadline offer only before the deadline" do
    travel_to(BEFORE) { get pricing_path }
    assert_match "($299 value)", response.body
    assert_match "26 days left", response.body

    travel_to(AFTER) { get pricing_path }
    assert_no_match "DSCSA deadline offer", response.body
  end
end
