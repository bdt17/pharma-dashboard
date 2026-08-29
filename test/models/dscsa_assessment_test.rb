require "test_helper"

class DscsaAssessmentTest < ActiveSupport::TestCase
  def answers(default: "yes", **overrides)
    DscsaAssessment::ALL_KEYS
      .index_with { |k| overrides[k.to_sym] || default }
      .with_indifferent_access
  end

  test "all yes scores 100 and is well positioned" do
    a = DscsaAssessment.build_from(answers(default: "yes"))
    assert_equal 100, a.score
    assert_equal "well_positioned", a.band
    assert_empty a.gaps
  end

  test "all no scores 0 with significant gaps" do
    a = DscsaAssessment.build_from(answers(default: "no"))
    assert_equal 0, a.score
    assert_equal "significant_gaps", a.band
    assert_equal DscsaAssessment::QUESTIONS.size, a.gaps.size
  end

  test "unsure is worth half and is treated as a gap" do
    a = DscsaAssessment.build_from(answers(default: "unsure"))
    assert_equal 50, a.score
    assert_equal DscsaAssessment::QUESTIONS.size, a.gaps.size
  end

  test "the exemption question is context only, not scored" do
    with = DscsaAssessment.build_from(answers(default: "yes", exemption: "no"))
    assert_equal 100, with.score
    assert_not with.still_exempt?
  end

  test "unknown answer values fall back to unsure" do
    a = DscsaAssessment.build_from(answers(default: "yes", records: "banana"))
    assert_equal "unsure", a.answers["records"]
  end

  test "gets a unique token and is addressable by it" do
    a = DscsaAssessment.build_from(answers)
    a.save!
    assert a.token.present?
    assert_equal a, DscsaAssessment.find_by(token: a.token)
    assert_equal a.token, a.to_param
  end

  test "rejects a malformed email but allows a blank one" do
    ok = DscsaAssessment.build_from(answers.merge("email" => ""))
    assert ok.valid?

    bad = DscsaAssessment.build_from(answers.merge("email" => "nope"))
    assert_not bad.valid?
  end
end
