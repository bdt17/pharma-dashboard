require "application_system_test_case"

class DscsaAssessmentTest < ApplicationSystemTestCase
  test "a visitor completes the readiness check and sees a scored result" do
    visit dscsa_assessment_path
    assert_selector "h1", text: "Where does your pharmacy actually stand?"

    # Answer the context question and every scored one -- "Yes" to the first
    # few, "No" to the rest, so the result has both strengths and gaps.
    all("fieldset").each_with_index do |fieldset, i|
      within(fieldset) { choose(i.even? ? "Yes" : "No") }
    end

    fill_in "Pharmacy (optional)", with: "Test Pharmacy"
    click_on "See my readiness score"

    assert_current_path %r{/dscsa-assessment/[\w-]+}
    assert_selector "span.mono", text: %r{\A\d+\z}     # the big score number
    assert_text "Gaps to close"
    assert_selector "form[action='#{request_a_call_path}']"  # the book-a-call form
    assert_link "Start free trial"
  end
end
