require "test_helper"

class GuidesTest < ActionDispatch::IntegrationTest
  test "the index lists every guide" do
    get guides_path
    assert_response :success
    Guide::ALL.each { |guide| assert_select "a[href=?]", guide_path(guide.slug), text: guide.title }
  end

  test "every guide renders with its title, review date, disclaimer and the readiness check" do
    Guide::ALL.each do |guide|
      get guide_path(guide.slug)
      assert_response :success, guide.slug
      assert_select "title", /#{Regexp.escape(guide.title)}/
      assert_select "meta[name=description][content=?]", guide.summary
      assert_select "h1", guide.title
      assert_match "Last reviewed #{Guide::REVIEWED_ON.strftime('%B %-d, %Y')}", response.body
      assert_match "not legal advice", response.body
      assert_select "a[href=?]", dscsa_assessment_path
    end
  end

  test "guides state the checked facts, not the outdated ones" do
    texts = Guide::SLUGS.map { |slug| get(guide_path(slug)) && Nokogiri::HTML(response.body).at("main, body").text.squish }.join(" ")
    assert_match "at least six years", texts
    assert_match "within two business days", texts
    assert_match "30 or more hours a week", texts
    # Transaction history stopped being exchanged in 2023 -- no guide may tell pharmacies to keep it.
    assert_no_match(/(keep|retain|retrievable)[^.]{0,40}transaction history|transaction history[^.]{0,40}(keep|retain|retrievable)/i, texts)
  end

  test "unknown guides are a 404" do
    get "/guides/not-a-guide"
    assert_response :not_found
  end

  test "the sitemap lists public pages and every guide, and robots.txt points to it" do
    get sitemap_path
    assert_response :success
    assert_equal "application/xml", response.media_type
    xml = Nokogiri::XML(response.body)
    locs = xml.css("loc").map(&:text)
    assert_includes locs, dscsa_assessment_url
    Guide::SLUGS.each { |slug| assert_includes locs, guide_url(slug) }
    assert locs.none? { |loc| loc.include?("/dashboard") || loc.include?("/ops") }
    assert_includes File.read(Rails.root.join("public/robots.txt")), "Sitemap: https://pharmatransport.org/sitemap.xml"
  end
end
