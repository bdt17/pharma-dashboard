require "test_helper"
require "pdf/reader"
require "stringio"

class DscsaReadinessReportTest < ActiveSupport::TestCase
  def build(answers, pharmacy_name: "Main Street Pharmacy")
    params = DscsaAssessment::ALL_KEYS.index_with { "yes" }.merge(answers).merge(pharmacy_name: pharmacy_name)
    DscsaAssessment.build_from(params.with_indifferent_access).tap(&:save!)
  end

  def text_of(assessment)
    bytes = DscsaReadinessReport.new(assessment, result_url: "https://example.test/r/#{assessment.token}").generate
    PDF::Reader.new(StringIO.new(bytes)).pages.map(&:text).join(" ").squish
  end

  test "lists every gap with its requirement and a concrete first step, and the strengths" do
    assessment = build({ "custody" => "no", "sops" => "unsure" })
    text = text_of(assessment)

    assert_includes text, "Main Street Pharmacy"
    assert_includes text, "#{assessment.score} / 100"
    assert_includes text, "2 of 8 areas to close"
    assert_includes text, "Chain of custody"
    assert_includes text, "Written procedures"
    assert_includes text, "have every staff member sign"
    assert_includes text, "Pharma Transport records this automatically"
    assert_includes text, "Already in place"
    assert_includes text, "Cold chain"
    assert_includes text, "https://example.test/r/#{assessment.token}"
  end

  test "every question has a next step" do
    DscsaAssessment::QUESTIONS.each do |q|
      assert DscsaAssessment.next_step_for(q).present?, q[:key]
    end
  end

  test "renders every gap at once, across pages, without unsupported glyphs" do
    assessment = build(DscsaAssessment::QUESTIONS.to_h { |q| [ q[:key], "no" ] })
    text = text_of(assessment)

    assert_includes text, "8 of 8 areas to close"
    DscsaAssessment::QUESTIONS.each { |q| assert_includes text, q[:category] }
    assert_includes text, "Page 2 of"
  end

  test "an all-yes assessment says so instead of an empty plan" do
    text = text_of(build({}))
    assert_includes text, "You answered every question"
  end

  test "deadline copy and the free-setup offer switch on their own dates" do
    assessment = build({ "custody" => "no" })

    travel_to Time.utc(2026, 11, 1, 15) do
      text = text_of(assessment)
      assert_includes text, "extended the DSCSA small-dispenser exemption to November 27, 2027"
      assert_includes text, "by December 31, 2026"
    end

    travel_to Time.utc(2027, 1, 15, 15) do
      assert_not_includes text_of(assessment), "for free"
    end

    travel_to Time.utc(2027, 12, 1, 15) do
      assert_includes text_of(assessment), "exemption ended on November 27, 2027"
    end
  end

  test "an exemption answer of no says the requirements already apply" do
    text = text_of(build({ "exemption" => "no", "custody" => "no" }))
    assert_includes text, "already in force"
  end

  test "filename uses the pharmacy name when given" do
    assessment = build({})
    assert_match(/\Adscsa-readiness-main-street-pharmacy-\d{4}-\d{2}-\d{2}\.pdf\z/, DscsaReadinessReport.new(assessment, result_url: "x").filename)
    assert_match(/\Adscsa-readiness-\d{4}-\d{2}-\d{2}\.pdf\z/, DscsaReadinessReport.new(build({}, pharmacy_name: ""), result_url: "x").filename)
  end
end
