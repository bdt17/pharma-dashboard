xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @urls.each do |url|
    xml.url do
      xml.loc url
      xml.lastmod @guides_lastmod.iso8601 if url.include?("/guides/")
    end
  end
end
