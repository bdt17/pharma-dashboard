require "test_helper"

class DscsaAssessmentsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  def full_answers(default: "yes", **overrides)
    DscsaAssessment::ALL_KEYS.index_with { |k| overrides[k.to_sym] || default }
  end

  test "new renders the questionnaire" do
    get dscsa_assessment_url
    assert_response :success
    assert_select "fieldset legend", minimum: DscsaAssessment::QUESTIONS.size
  end

  test "create scores the answers and redirects to the tokened result" do
    assert_difference "DscsaAssessment.count", 1 do
      # two of eight scored questions answered "yes" -> 4 / 16 -> 25
      post dscsa_assessment_url, params: full_answers(default: "no", exceptions: "yes", records: "yes")
    end
    assessment = DscsaAssessment.last
    assert_redirected_to dscsa_assessment_result_path(assessment.token)
    assert_equal 25, assessment.score
  end

  test "result page shows the score, the gaps, and the call form" do
    post dscsa_assessment_url, params: full_answers(default: "yes", transaction_data: "no", partners: "unsure")
    follow_redirect!

    assert_response :success
    assert_select "form[action=?]", request_a_call_path
    assert_match "Transaction data", response.body
    assert_match "Trading partners", response.body
  end

  test "result 404s on an unknown token" do
    get dscsa_assessment_result_url("does-not-exist")
    assert_response :not_found
  end

  test "email captured on the assessment prefills the call form" do
    post dscsa_assessment_url, params: full_answers(default: "no").merge(email: "lead@example.com", pharmacy_name: "Lead Rx")
    follow_redirect!

    assert_select "input[name=?][value=?]", "call_request[email]", "lead@example.com"
    assert_select "input[name=?][value=?]", "call_request[pharmacy_name]", "Lead Rx"
  end

  test "an email on the assessment sends the result now and schedules the day3/day7 follow-ups" do
    assert_enqueued_emails 1 do
      assert_enqueued_jobs 2, only: DscsaAssessmentFollowUpJob do
        post dscsa_assessment_url, params: full_answers(default: "no").merge(email: "lead@example.com")
      end
    end

    steps = enqueued_jobs.select { |j| j["job_class"] == "DscsaAssessmentFollowUpJob" }.map { |j| j["arguments"].last }
    assert_equal %w[day3 day7], steps.sort
  end

  test "no email on the assessment sends nothing and schedules nothing" do
    assert_no_enqueued_emails do
      assert_no_enqueued_jobs(only: DscsaAssessmentFollowUpJob) do
        post dscsa_assessment_url, params: full_answers(default: "no")
      end
    end
  end
end
