Rails.application.routes.draw do
  devise_for :users

  # Public pages
  root "home#index"
  get "/login", to: "home#login", as: :login
  get "/landing", to: "home#landing"
  get "/signup", to: "home#signup"
  get "/health", to: "home#health"

  # Authenticated application pages
  get "/dashboard", to: "dashboard#index", as: :dashboard
  get "/enterprise/dashboard", to: "dashboard#index"
  get "/gps", to: "home#gps"
  get "/billing", to: "billing#index", as: :billing
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

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :vehicles, only: %i[index show]
      post "/gps", to: "gps#create"
    end
  end
end
