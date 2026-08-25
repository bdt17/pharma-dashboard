Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

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

  # Authenticated application pages
  get "/dashboard", to: "dashboard#index", as: :dashboard
  get "/enterprise/dashboard", to: "dashboard#index"
  get "/gps", to: "home#gps"
  get "/billing", to: "billing#index", as: :billing
  post "/billing/checkout", to: "billing#checkout", as: :billing_checkout
  get "/billing/success", to: "billing#success", as: :billing_success
  get "/billing/cancel", to: "billing#cancel", as: :billing_cancel
  get "/compliance", to: "compliance#index", as: :compliance
  get "/subscribe", to: redirect("/billing")

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
