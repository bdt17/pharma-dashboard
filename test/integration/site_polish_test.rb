require "test_helper"

# Things a visitor or a link preview sees before they ever sign in:
# branded error pages, a raster share image, icons, canonical URLs.
class SitePolishTest < ActionDispatch::IntegrationTest
  %w[400 404 422 500].each do |code|
    test "public/#{code}.html is a branded, self-contained page" do
      path = Rails.root.join("public/#{code}.html")
      assert path.exist?, "missing #{path} -- Rails serves a blank page without it"
      html = path.read
      assert_includes html, "Pharma Transport"
      assert_includes html, "ERROR #{code}"
      assert_includes html, 'name="viewport"'
      assert_includes html, 'name="robots" content="noindex"'
      assert_no_match(/<script|src="http|href="http/, html, "error pages must not depend on anything that might be down")
    end
  end

  test "public pages carry canonical, icons and a raster share image" do
    get "/pricing?utm_source=test"
    assert_response :success
    assert_select 'link[rel="canonical"][href="http://www.example.com/pricing"]'
    assert_select 'link[rel="apple-touch-icon"][href="/apple-touch-icon.png"]'
    assert_select 'meta[property="og:image"]' do |tags|
      assert_match(/og-[0-9a-f]+\.png\z/, tags.first["content"])
    end
    assert_select 'meta[property="og:image:alt"]'
  end

  test "icon files exist" do
    assert Rails.root.join("public/apple-touch-icon.png").exist?
    assert Rails.root.join("public/icon.png").exist?
    assert Rails.root.join("app/assets/images/og.png").exist?
  end

  test "every guide has a search description of useful length" do
    Guide::ALL.each do |guide|
      assert_includes 110..160, guide.description.length, "#{guide.slug}: #{guide.description.length} chars"
    end
    get "/guides/#{Guide::ALL.first.slug}"
    assert_select %(meta[name="description"][content=?]), Guide::ALL.first.description
  end
end
