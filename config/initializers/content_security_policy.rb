# Content Security Policy: the browser refuses any script, style, font,
# frame, or form target not listed here, so an injected <script> (or a
# compromised third-party include) can't run. Scripts are limited to this
# origin plus a per-request nonce -- importmap's inline map and the Google
# Ads tag (ConversionTrackingHelper) carry it; there are no other inline
# scripts or on*= handlers in the app.
#
# style-src keeps 'unsafe-inline' because the views use style="" attributes
# throughout; inline styles can't execute code, so that's the standard
# trade-off. form-action lists Stripe because Chrome applies it to the
# redirect after the Checkout / Billing Portal form posts.
Rails.application.configure do
  # Google's hosts are well-known CSP bypass gadgets (JSONP endpoints, any
  # GTM container), so they're allowed only once the Ads tag is actually
  # configured -- until then the policy is just 'self' plus the nonce.
  google_ads =
    if ENV["GOOGLE_ADS_CONVERSION_ID"].present?
      %w[https://www.googletagmanager.com https://www.googleadservices.com https://www.google.com https://googleads.g.doubleclick.net]
    else
      []
    end

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.object_src  :none
    policy.frame_ancestors :self
    policy.form_action :self, "https://checkout.stripe.com", "https://billing.stripe.com"
    policy.script_src  :self, *google_ads
    policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :https
    policy.connect_src :self, *google_ads
    policy.frame_src   google_ads.any? ? "https://www.googletagmanager.com" : :none
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end

# Turn off browser features the app never uses, so injected or third-party
# code can't ask for them either. Set as a raw default header rather than
# with Rails' permissions_policy DSL: as of Rails 8.1 that DSL still emits
# the old Feature-Policy header name, which current browsers ignore.
Rails.application.config.action_dispatch.default_headers["Permissions-Policy"] =
  "camera=(), microphone=(), geolocation=(), usb=(), payment=(), gyroscope=(), magnetometer=(), fullscreen=(self)"
