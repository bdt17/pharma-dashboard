require "test_helper"

# Deadline-dependent copy switches on its own: the free-setup offer ends
# DeadlineOffer::ENDS, and pages switch tense the day after the DSCSA
# exemption ends. Pinned to fixed dates so these keep passing as real
# time goes by.
class DscsaDeadlineCopyTest < ActionDispatch::IntegrationTest
  OFFER_RUNNING = Time.utc(2026, 11, 1, 15)
  OFFER_OVER = Time.utc(2027, 1, 15, 15)
  AFTER = Time.utc(2027, 11, 29, 15)

  test "the DSCSA landing page" do
    travel_to(OFFER_RUNNING) { get dscsa_2026_path }
    assert_match "The FDA gave small pharmacies one more year", response.body
    assert_match "November 27, 2027", response.body
    assert_match "Free setup offer", response.body
    assert_no_match "isn&rsquo;t being extended", response.body

    travel_to(OFFER_OVER) { get dscsa_2026_path }
    assert_match "one more year", response.body
    assert_no_match "Free setup offer", response.body

    travel_to(AFTER) { get dscsa_2026_path }
    assert_match "The DSCSA exemption has ended", response.body
    assert_no_match "one more year", response.body
  end

  test "the home page callout" do
    travel_to(OFFER_RUNNING) { get root_path }
    assert_match "extended the small-dispenser exemption", response.body

    travel_to(AFTER) { get root_path }
    assert_match "the requirements apply to you now", response.body
  end

  test "the assessment asks about headcount as of the new qualifying date" do
    travel_to(OFFER_RUNNING) { get dscsa_assessment_path }
    assert_match "As of November 27, 2026, will your pharmacy", response.body
    assert_no_match "November 27, 2024", response.body

    travel_to(AFTER) { get dscsa_assessment_path }
    assert_match "now that the small-dispenser exemption has ended", response.body
  end

  test "the blog post reports the extension, and an update note only after the date" do
    travel_to(OFFER_RUNNING) { get blog_dscsa_exemption_2026_path }
    assert_match "Extended to November 27, 2027", response.body
    assert_match "What still applies today", response.body
    assert_no_match "this date has now passed", response.body

    travel_to(AFTER) { get blog_dscsa_exemption_2026_path }
    assert_match "this date has now passed", response.body
  end

  test "the pricing page shows the free setup offer only while it runs" do
    travel_to(OFFER_RUNNING) { get pricing_path }
    assert_match "($299 value)", response.body
    assert_match "by December 31, 2026", response.body
    assert_match "60 days left", response.body

    travel_to(OFFER_OVER) { get pricing_path }
    assert_no_match "Free setup offer", response.body
  end
end
