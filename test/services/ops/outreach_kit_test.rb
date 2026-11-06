require "test_helper"

class Ops::OutreachKitTest < ActiveSupport::TestCase
  def kit = Ops::OutreachKit.new(url_options: { host: "pharmatransport.org", protocol: "https" })

  test "builds a tagged link to the chosen landing page" do
    assert_equal "https://pharmatransport.org/independent-pharmacy?utm_campaign=az-assoc-dec&utm_source=association",
                 kit.link(page: "independent_pharmacy", source: "association", campaign: "AZ Assoc Dec!")
  end

  test "unknown page and source fall back instead of raising" do
    link = kit.link(page: "nope", source: "spam", campaign: "x")
    assert_match %r{\Ahttps://pharmatransport.org/dscsa-assessment\?}, link
    assert_includes link, "utm_source=linkedin"
  end

  test "campaign slug is URL-safe and capped" do
    assert_equal "a-b-c", Ops::OutreachKit.campaign_slug("  A / b __ c  ")
    assert_equal UtmTracking::MAX_LENGTH, Ops::OutreachKit.campaign_slug("x" * 500).length
  end

  test "templates carry the extension dates and the offer while it runs" do
    travel_to Time.utc(2026, 11, 6, 15) do
      bodies = kit.templates.map(&:body).join("\n")
      assert_includes bodies, DscsaDeadline.label
      assert_includes bodies, DscsaDeadline.qualifying_label
      assert_includes bodies, "before #{DeadlineOffer.label}"
      assert_not_includes bodies, "Amazon"
    end
  end

  test "offer lines drop out once the offer has ended" do
    travel_to Time.utc(2027, 1, 2, 15) do
      bodies = kit.templates.map(&:body).join("\n")
      assert_not_includes bodies, "at no charge"
      assert_includes bodies, DscsaDeadline.label
    end
  end

  test "templates switch tense once the exemption has ended" do
    travel_to Time.utc(2027, 11, 29, 15) do
      bodies = kit.templates.map(&:body).join("\n")
      assert_includes bodies, "ended on #{DscsaDeadline.label}"
      assert_not_includes bodies, "extended the small-dispenser exemption"
    end
  end

  test "every tagged template link names its own campaign" do
    links = kit.templates.filter_map(&:link)
    assert_equal links.size, links.map { |l| l[/utm_campaign=[^&]+/] }.uniq.size
  end

  test "connection note fits LinkedIn's 300 characters" do
    note = kit.templates.find { |t| t.key == "linkedin_connect" }.body
    assert_operator note.length, :<=, 300
  end

  test "no blank-line runs or trailing spaces" do
    kit.templates.each do |template|
      assert_no_match(/\n{3,}/, template.body, template.key)
      assert_no_match(/[ \t]+$/, template.body, template.key)
    end
  end
end
