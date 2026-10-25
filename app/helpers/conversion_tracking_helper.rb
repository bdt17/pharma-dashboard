module ConversionTrackingHelper
  # Google Ads conversion tracking, dormant until GOOGLE_ADS_CONVERSION_ID
  # is set as a Render env var -- the same "safe until configured" pattern
  # as Stripe / Twilio / Sentry / Postmark. Until then nothing renders and
  # no Google script loads.
  #
  # Two pieces:
  #   google_ads_base_tag       -> the gtag.js loader, once, in <head>
  #   google_ads_conversion(k)  -> a single conversion event fired from one
  #                                thank-you page, gated on its own
  #                                per-event label env var so an unlabelled
  #                                event stays silent instead of firing
  #                                against a blank send_to
  #
  # Event -> label env var (the "conversion label" Google shows next to
  # each conversion action you create under Tools -> Conversions):
  #   :assessment -> GOOGLE_ADS_LABEL_ASSESSMENT  (DSCSA assessment completed)
  #   :trial      -> GOOGLE_ADS_LABEL_TRIAL       (Stripe checkout success)
  #   :call       -> GOOGLE_ADS_LABEL_CALL        (request-a-call submitted)
  CONVERSION_EVENTS = {
    assessment: "GOOGLE_ADS_LABEL_ASSESSMENT",
    trial:      "GOOGLE_ADS_LABEL_TRIAL",
    call:       "GOOGLE_ADS_LABEL_CALL"
  }.freeze

  def google_ads_conversion_id
    ENV["GOOGLE_ADS_CONVERSION_ID"].presence
  end

  def google_ads_base_tag
    id = google_ads_conversion_id
    return unless id

    safe_join([
      javascript_include_tag("https://www.googletagmanager.com/gtag/js?id=#{ERB::Util.url_encode(id)}", async: true),
      javascript_tag(<<~JS.strip)
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', #{id.to_json});
      JS
    ])
  end

  def google_ads_conversion(event)
    id = google_ads_conversion_id
    label = ENV[CONVERSION_EVENTS.fetch(event)].presence
    return unless id && label

    javascript_tag("gtag('event', 'conversion', {send_to: #{"#{id}/#{label}".to_json}});")
  end
end
