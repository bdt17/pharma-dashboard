require "test_helper"

# Renders every public page and the customer emails on the mornings their
# dates change -- the day after the headcount date, the day the free-setup
# offer ends, and the day after the exemption ends -- and checks nothing
# still says something that stopped being true. Times are 15:00 UTC, i.e.
# early morning US Eastern, the zone DscsaDeadline judges dates in.
class DateSweepTest < ActionDispatch::IntegrationTest
  TODAY = Time.utc(2026, 11, 6, 15)
  AFTER_QUALIFYING = Time.utc(2026, 11, 28, 15)
  AFTER_OFFER = Time.utc(2027, 1, 1, 15)
  AFTER_EXEMPTION = Time.utc(2027, 11, 28, 15)

  PAGES = %i[root_path dscsa_2026_path independent_pharmacy_path pricing_path security_path
             blog_dscsa_exemption_2026_path dscsa_assessment_path compliance_officer_path about_path guides_path].freeze

  # Wording that names the old 2026 deadline as if it were still ahead.
  # ("was due to end on November 27, 2026" is history, and fine.)
  OLD_DEADLINE = /(?<!due to )\bends?( on)? November(&nbsp;|\s)27,(&nbsp;|\s)2026|exemption ends (on )?Nov(ember)? 27,? 2026/

  def render_all(time)
    travel_to(time) do
      paths = PAGES.map { |page| public_send(page) } + Guide::SLUGS.map { |slug| guide_path(slug) }
      paths.map do |path|
        get path
        assert_response :success, "#{path} at #{time}"
        [ path, response.body ]
      end.to_h
    end
  end

  test "no page ever calls November 27, 2026 the deadline" do
    [ TODAY, AFTER_QUALIFYING, AFTER_OFFER, AFTER_EXEMPTION ].each do |time|
      render_all(time).each { |page, body| assert_no_match OLD_DEADLINE, body, "#{page} at #{time}" }
    end
  end

  test "the headcount question switches to past tense after November 27, 2026" do
    travel_to(TODAY) { get dscsa_assessment_path }
    assert_match "will your pharmacy&#39;s owner employ", response.body

    travel_to(AFTER_QUALIFYING) { get dscsa_assessment_path }
    assert_match "did your pharmacy&#39;s owner employ", response.body
    assert_no_match "will your pharmacy", response.body
  end

  test "no page mentions the free-setup offer or the founding offer after December 31" do
    render_all(AFTER_OFFER).each do |page, body|
      assert_no_match(/Free setup offer|\(\$299 value\)|Founding customer offer/, body, page)
    end
  end

  test "nothing says the exemption is still ahead once it has ended" do
    render_all(AFTER_EXEMPTION).each do |page, body|
      assert_no_match(/one more year|exemption ends on|extended to November(&nbsp;|\s)27,(&nbsp;|\s)2027/, body, page)
    end
  end

  test "the DSCSA page title follows the exemption" do
    travel_to(TODAY) { get dscsa_2026_path }
    assert_select "title", /Extended to 2027/
    travel_to(AFTER_EXEMPTION) { get dscsa_2026_path }
    assert_select "title", /Has Ended/
  end

  test "customer emails drop the offer after December 31" do
    org = Organization.create!(name: "Main Street Rx")
    admin = User.create!(email: "owner@example.com", password: "password123!", organization: org, role: "admin")
    assessment = DscsaAssessment.build_from({ "custody" => "no", email: "lead@example.com" }.with_indifferent_access)
    assessment.save!

    travel_to(AFTER_OFFER) do
      mails = [ OnboardingMailer.nudge(admin, 1), OnboardingMailer.nudge(admin, 3),
                DscsaAssessmentMailer.result_email(assessment), DscsaAssessmentMailer.follow_up_day3(assessment),
                DscsaAssessmentMailer.follow_up_day7(assessment) ]
      mails.each do |mail|
        body = mail.html_part.body.to_s + mail.text_part.body.to_s
        assert_no_match(/at no charge|free \(normally|Founding customer offer|\(\$299 value\)/, body, mail.subject)
        assert_no_match OLD_DEADLINE, body, mail.subject
      end
    end
  end

  test "the readiness PDF drops the offer after December 31" do
    assessment = DscsaAssessment.build_from({ "custody" => "no" }.with_indifferent_access)
    assessment.save!
    travel_to(AFTER_OFFER) do
      text = PDF::Reader.new(StringIO.new(DscsaReadinessReport.new(assessment, result_url: "https://example.com/r").generate))
                        .pages.map(&:text).join(" ").squish
      assert_no_match(/free setup|\$299/i, text)
      assert_no_match(/November 27, 2026/, text.gsub(/headcount[^.]*November 27, 2026/i, ""))
    end
  end
end
