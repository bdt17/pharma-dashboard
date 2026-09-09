# First-touch UTM attribution for the acquisition funnel. A visitor can
# land on /dscsa-2026 (or any page) from a Google Ad or a marketing email
# with ?utm_source=...&utm_campaign=... in the URL, then wander the site
# for a while -- read the landing page, take the DSCSA assessment, maybe
# sign up -- days apart, across several page loads that carry no query
# string at all. Threading utm_source/utm_campaign through every link and
# form on every marketing page to survive that is exactly the kind of
# thing that quietly breaks the first time someone adds a new CTA and
# forgets it. A cookie set once on the first hit and read back wherever a
# record is actually created (DscsaAssessment, CallRequest, a new
# Organization) survives all of that for free.
#
# First-touch, not last-touch: once the cookie is set it is never
# overwritten, so the campaign that actually brought the visitor in gets
# the credit -- not whichever internal link (or a second, later ad click)
# happens to carry its own utm params during the same attribution window.
# Encrypted rather than a plain cookie only so a visitor can't hand-edit
# it to pollute the acquisition numbers; there's nothing sensitive in it.
module UtmTracking
  extend ActiveSupport::Concern

  COOKIE_NAME = :pt_utm
  MAX_LENGTH = 100
  ATTRIBUTION_WINDOW = 30.days

  included do
    before_action :capture_utm_params
  end

  private

  def capture_utm_params
    return if cookies.encrypted[COOKIE_NAME].present? # first touch already recorded

    source = params[:utm_source].to_s.strip.first(MAX_LENGTH).presence
    campaign = params[:utm_campaign].to_s.strip.first(MAX_LENGTH).presence
    return unless source || campaign

    cookies.encrypted[COOKIE_NAME] = {
      value: { source: source, campaign: campaign }.to_json,
      expires: ATTRIBUTION_WINDOW,
      httponly: true,
      same_site: :lax
    }
  end

  def utm_source
    stored_utm["source"]
  end

  def utm_campaign
    stored_utm["campaign"]
  end

  def stored_utm
    @stored_utm ||= JSON.parse(cookies.encrypted[COOKIE_NAME].presence || "{}")
  rescue JSON::ParserError
    {}
  end
end
