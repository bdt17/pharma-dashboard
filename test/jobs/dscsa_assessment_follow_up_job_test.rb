require "test_helper"

class DscsaAssessmentFollowUpJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  def build_assessment(default: "yes", **overrides)
    params = DscsaAssessment::ALL_KEYS
      .index_with { |k| overrides[k.to_sym] || default }
      .with_indifferent_access
      .merge(email: "lead@example.com", pharmacy_name: "Lead Rx")

    DscsaAssessment.build_from(params).tap(&:save!)
  end

  test "sends the day3 email when there's a gap to lead with" do
    assessment = build_assessment(custody: "no")

    assert_enqueued_emails 1 do
      DscsaAssessmentFollowUpJob.perform_now(assessment.id, "day3")
    end
  end

  test "skips day3 when the assessment has no gaps" do
    assessment = build_assessment

    assert_no_enqueued_emails do
      DscsaAssessmentFollowUpJob.perform_now(assessment.id, "day3")
    end
  end

  test "sends the day7 email regardless of gaps" do
    assessment = build_assessment

    assert_enqueued_emails 1 do
      DscsaAssessmentFollowUpJob.perform_now(assessment.id, "day7")
    end
  end

  test "skips when the email has unsubscribed" do
    assessment = build_assessment(custody: "no")
    EmailSuppression.suppress!("lead@example.com")

    assert_no_enqueued_emails do
      DscsaAssessmentFollowUpJob.perform_now(assessment.id, "day3")
      DscsaAssessmentFollowUpJob.perform_now(assessment.id, "day7")
    end
  end

  test "skips when the email has since become an active or trialing subscriber" do
    assessment = build_assessment(custody: "no")
    organization = Organization.create!(name: "Lead Rx")
    User.create!(email: "lead@example.com", password: "password123!", organization: organization, role: "admin")
    Subscription.create!(organization: organization, stripe_subscription_id: "sub_1", status: "trialing")

    assert_no_enqueued_emails do
      DscsaAssessmentFollowUpJob.perform_now(assessment.id, "day3")
    end
  end

  test "still sends when the same email belongs to a user with no active subscription" do
    assessment = build_assessment(custody: "no")
    organization = Organization.create!(name: "Lead Rx")
    User.create!(email: "lead@example.com", password: "password123!", organization: organization, role: "admin")

    assert_enqueued_emails 1 do
      DscsaAssessmentFollowUpJob.perform_now(assessment.id, "day3")
    end
  end

  test "does nothing if the assessment was deleted" do
    assessment = build_assessment(custody: "no")
    id = assessment.id
    assessment.destroy

    assert_no_enqueued_emails do
      DscsaAssessmentFollowUpJob.perform_now(id, "day3")
    end
  end

  test "raises on an unrecognized step rather than silently doing nothing" do
    assessment = build_assessment(custody: "no")

    assert_raises(ArgumentError) { DscsaAssessmentFollowUpJob.perform_now(assessment.id, "day30") }
  end
end
