Rails.application.routes.draw do
  # The dashboard.<domain> vanity-host redirect lives in Rack middleware
  # (DashboardSubdomainRedirect), not here -- a catch-all route with an
  # explicit `via: :head` shadowed the implicit HEAD handling on `root`,
  # which broke `HEAD /` (Render's health check) for every host.

  devise_for :users, controllers: { registrations: "users/registrations" }

  # Two-factor authentication (TOTP). Mandatory for admins/pharmacists, opt-in
  # otherwise; see config/initializers/two_factor.rb and
  # ApplicationController#enforce_two_factor.
  resource :two_factor_setup, only: %i[show create destroy], controller: "two_factor/setup"
  resource :two_factor_challenge, only: %i[new create], controller: "two_factor/challenge"
  resource :two_factor_backup_codes, only: %i[show create], controller: "two_factor/backup_codes"

  # Public pages
  root "home#index"
  get "/login", to: "home#login", as: :login
  get "/landing", to: "home#landing"
  get "/signup", to: "home#signup"
  get "/health", to: "home#health"
  get "/terms", to: "legal#terms", as: :terms
  get "/privacy", to: "legal#privacy", as: :privacy
  get "/blog/small-pharmacy-dscsa-exemption-2026", to: "blog#dscsa_exemption_2026", as: :blog_dscsa_exemption_2026
  get "/pricing", to: "pages#pricing", as: :pricing
  get "/about", to: "pages#about", as: :about
  get "/security", to: "pages#security", as: :security
  get "/compliance-officer", to: "pages#compliance_officer", as: :compliance_officer

  # Dedicated paid-search / content landing page for "small pharmacy DSCSA
  # 2026" and similar terms -- message-matched to the ad copy, so it's a
  # separate page from the general marketing pricing page rather than
  # sending that traffic to /pricing directly. See PagesController#dscsa_2026.
  get "/dscsa-2026", to: "pages#dscsa_2026", as: :dscsa_2026
  get "/verify/:token", to: "verifications#show", as: :verification
  # Embeddable SVG version of the badge -- a pharmacy drops this on its own
  # site (see the snippet on the Billing page), and every embed links back
  # to the full verification page. `format: false` keeps the ".svg" a
  # literal part of the path, not a Rails format token.
  get "/verify/:token/badge.svg", to: "verifications#badge", as: :verification_badge, format: false

  # DSCSA readiness self-assessment (acquisition funnel)
  get  "/dscsa-assessment", to: "dscsa_assessments#new", as: :dscsa_assessment
  post "/dscsa-assessment", to: "dscsa_assessments#create"
  get  "/dscsa-assessment/:token", to: "dscsa_assessments#result", as: :dscsa_assessment_result

  # Inbound "request a call" leads from the marketing pages
  get  "/request-a-call", to: "call_requests#new", as: :request_a_call
  post "/request-a-call", to: "call_requests#create"
  get  "/request-a-call/thanks", to: "call_requests#thanks", as: :call_request_thanks

  # One-click unsubscribe from marketing-style email (see EmailSuppression).
  # A signed token, not a raw email address -- see UnsubscribesController.
  get "/unsubscribe", to: "unsubscribes#show", as: :unsubscribe

  # Operator diagnostics -- integration health at a glance. Gated to an
  # OPERATOR_EMAILS allowlist (see OpsController).
  get  "/ops", to: "ops#index", as: :ops
  post "/ops/test-email", to: "ops#test_email", as: :ops_test_email

  # Authenticated application pages
  get "/dashboard", to: "dashboard#index", as: :dashboard
  get "/enterprise/dashboard", to: "dashboard#index"
  get "/gps", to: "home#gps"
  get "/billing", to: "billing#index", as: :billing
  post "/billing/checkout", to: "billing#checkout", as: :billing_checkout
  post "/billing/addon_checkout", to: "billing#addon_checkout", as: :billing_addon_checkout
  post "/billing/portal", to: "billing#portal", as: :billing_portal
  patch "/billing/overage", to: "billing#overage", as: :billing_overage
  get "/billing/success", to: "billing#success", as: :billing_success
  get "/billing/cancel", to: "billing#cancel", as: :billing_cancel
  get "/compliance", to: "compliance#index", as: :compliance
  get "/subscribe", to: redirect("/billing")

  # SMS temperature-excursion alert recipients (Pro/Compliance tiers)
  get    "/alerts", to: "alert_settings#index", as: :alert_settings
  post   "/alerts/recipients", to: "alert_settings#create", as: :alert_recipients
  delete "/alerts/recipients/:id", to: "alert_settings#destroy", as: :alert_recipient
  post   "/alerts/recipients/:id/test", to: "alert_settings#test", as: :test_alert_recipient
  patch  "/alerts/quiet_hours", to: "alert_settings#quiet_hours", as: :alert_quiet_hours

  # Outbound event webhooks (Compliance tier)
  get    "/webhooks", to: "webhook_endpoints#index", as: :webhook_endpoints
  post   "/webhooks", to: "webhook_endpoints#create"
  patch  "/webhooks/:id", to: "webhook_endpoints#update"
  delete "/webhooks/:id", to: "webhook_endpoints#destroy", as: :webhook_endpoint
  post   "/webhooks/:id/enable", to: "webhook_endpoints#enable", as: :enable_webhook_endpoint
  post   "/webhooks/:id/test", to: "webhook_endpoints#test", as: :test_webhook_endpoint
  get    "/webhooks/:webhook_endpoint_id/deliveries", to: "webhook_deliveries#index", as: :webhook_endpoint_deliveries
  post   "/webhooks/:webhook_endpoint_id/deliveries/:id/replay", to: "webhook_deliveries#replay", as: :replay_webhook_endpoint_delivery

  # Application endpoints
  get "/batches.pdf", to: "batches#index", as: :batches_pdf
  post "/stripe/webhooks", to: "stripe_webhooks#create"

  # Chain of custody
  get "/batches/:id/chain-of-custody.pdf", to: "batches#chain_of_custody", as: :batch_chain_of_custody_pdf
  get "/batches/:batch_id/custody_logs", to: "custody_logs#index", as: :batch_custody_logs
  get "/batches/:batch_id/custody_logs/new", to: "custody_logs#new", as: :new_batch_custody_log
  post "/batches/:batch_id/custody_logs", to: "custody_logs#create"
  get "/batches/:batch_id/custody_logs/:id", to: "custody_logs#show", as: :batch_custody_log

  # Compliance packets
  get "/batches/:batch_id/compliance_reports", to: "compliance_reports#index", as: :batch_compliance_reports
  post "/batches/:batch_id/compliance_reports", to: "compliance_reports#create"
  get "/batches/:batch_id/compliance_reports/:id", to: "compliance_reports#show", as: :batch_compliance_report
  get "/batches/:batch_id/compliance_reports/:id/download.pdf", to: "compliance_reports#download", as: :batch_compliance_report_download

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :vehicles, only: %i[index show]
      post "/gps", to: "gps#create"
    end
  end
end
