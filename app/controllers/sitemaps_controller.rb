# /sitemap.xml: every public, indexable page -- the marketing pages, the
# blog post, the readiness check and the DSCSA guides (see Guide). Built
# from routes so a renamed page can't leave a dead URL here. Replaces an
# empty public/sitemaps.xml that listed nothing.
class SitemapsController < ApplicationController
  PAGES = %i[root_url pricing_url dscsa_2026_url independent_pharmacy_url compliance_officer_url security_url
             about_url dscsa_assessment_url blog_dscsa_exemption_2026_url guides_url].freeze

  def show
    @urls = PAGES.map { |page| public_send(page) } + Guide::ALL.map { |guide| guide_url(guide.slug) }
    @guides_lastmod = Guide::REVIEWED_ON
    expires_in 1.hour, public: true
  end
end
