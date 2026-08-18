Rails.application.routes.draw do
  devise_for :users

  # Public pages
  root "home#index"
  get "/login", to: "home#login", as: :login
  get "/landing", to: "home#landing"
  get "/signup", to: "home#signup"
  get "/health", to: "home#health"

  # Authenticated application pages
  get "/dashboard", to: "home#enterprise_dashboard", as: :dashboard
  get "/enterprise/dashboard", to: "home#enterprise_dashboard"
  get "/gps", to: "home#gps"
  get "/billing", to: "home#billing"

  # Application endpoints
  get "/api/vehicles", to: "home#vehicles"
  get "/batches/:id/chain-of-custody.pdf", to: "home#chain_of_custody"
  get "/batches.pdf", to: "batches#index", as: :batches_pdf
  get "/subscribe", to: "home#subscribe"

  namespace :api, defaults: { format: :json } do
    resources :vehicles, only: %i[index show]
  end
end
