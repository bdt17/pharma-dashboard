require "test_helper"

class DscsaAssessmentMailerTest < ActionMailer::TestCase
  def build_assessment(default: "yes", **overrides)
    params = DscsaAssessment::ALL_KEYS
      .index_with { |k| overrides[k.to_sym] || default }
      .with_indifferent_access
      .merge(email: "lead@example.com", pharmacy_name: "Lead Rx")

    DscsaAssessment.build_from(params).tap(&:save!)
  end

  test "result_email includes the score, gaps, and an unsubscribe link" do
    assessment = build_assessment(default: "yes", custody: "no")

    mail = DscsaAssessmentMailer.result_email(assessment)

    assert_equal [ "lead@example.com" ], mail.to
    assert_match assessment.score.to_s, mail.subject
    [ mail.html_part, mail.text_part ].each do |part|
      body = part.body.encoded
      assert_match "Chain of custody", body
      assert_match "Unsubscribe", body
    end
  end

  test "follow_up_day3 leads with a platform-solved gap over a process gap" do
    assessment = build_assessment(default: "yes", custody: "no", sops: "no")

    mail = DscsaAssessmentMailer.follow_up_day3(assessment)

    [ mail.html_part, mail.text_part ].each do |part|
      body = part.body.encoded
      assert_match "Chain of custody", body
      assert_match "Pharma Transport closes it", body
      refute_match "fractional compliance officer", body
    end
  end

  test "follow_up_day3 points a process-only gap at the compliance officer retainer" do
    assessment = build_assessment(default: "yes", sops: "no")

    mail = DscsaAssessmentMailer.follow_up_day3(assessment)

    [ mail.html_part, mail.text_part ].each do |part|
      body = part.body.encoded
      assert_match "Written procedures", body
      assert_match "fractional compliance officer", body
    end
  end

  test "follow_up_day7 mentions the deadline and doesn't require any gaps" do
    assessment = build_assessment(default: "yes")

    mail = DscsaAssessmentMailer.follow_up_day7(assessment)

    [ mail.html_part, mail.text_part ].each do |part|
      body = part.body.encoded
      assert_match "November 27, 2026", body
      assert_match "Unsubscribe", body
    end
  end

  test "the founding offer only appears before its cutoff" do
    assessment = build_assessment(default: "yes")

    travel_to StripeBilling.founding_offer_cutoff - 1.day do
      mail = DscsaAssessmentMailer.follow_up_day7(assessment)
      assert_match "Founding customer offer", mail.html_part.body.encoded
    end

    travel_to StripeBilling.founding_offer_cutoff + 1.day do
      mail = DscsaAssessmentMailer.follow_up_day7(assessment)
      refute_match "Founding customer offer", mail.html_part.body.encoded
    end
  end

  test "follow-up emails switch tense after the deadline" do
    assessment = DscsaAssessment.build_from(DscsaAssessment::ALL_KEYS.index_with { "no" }.merge(email: "lead@example.com"))
    assessment.save!

    travel_to Time.utc(2026, 11, 1, 15) do
      assert_match "before Nov 27", DscsaAssessmentMailer.follow_up_day3(assessment).subject
      assert_match "isn't a soft deadline", DscsaAssessmentMailer.follow_up_day7(assessment).text_part.body.to_s
    end
    travel_to Time.utc(2026, 11, 29, 15) do
      assert_no_match "before Nov 27", DscsaAssessmentMailer.follow_up_day3(assessment).subject
      day7 = DscsaAssessmentMailer.follow_up_day7(assessment)
      assert_match "has passed", day7.text_part.body.to_s
      assert_match "took effect when the small-dispenser exemption ended", day7.html_part.body.to_s
      assert_match "has ended", DscsaAssessmentMailer.result_email(assessment).text_part.body.to_s
    end
  end
end
