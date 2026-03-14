Rails.application.routes.draw do
  # Devise
  devise_for :users
  
  # Enterprise Routes (Phase 10)
  root "home#index"
  get  "/login",          to: "home#login", as: :login
  get  "/users/sign_in",  to: "home#login"
  get  "/users/sign_up",  to: "home#login"
  get  "/dashboard",      to: "home#enterprise_dashboard"
  get  "/enterprise/dashboard", to: "home#enterprise_dashboard"
  get  "/gps",            to: "home#gps"
  
  # API Endpoints (Phase 10 LIVE)
  get  "/api/vehicles",   to: "home#vehicles"
  get  "/batches/:id/chain-of-custody.pdf", to: "home#chain_of_custody"
  
  # Health + Legacy
  get "/health", to: "home#health"
  get "/billing", to: "home#billing"
  get "/subscribe", to: "home#subscribe"
  
  # Frontend stubs
  get "/landing", to: "home#landing"
  get "/signup", to: "home#signup"
end

get "/subscribe", to: "subscribe#index"
get "/subscribe", to: "subscribe#index"
get "/batches/1/chain-of-custody.pdf", to: "batches#show"
namespace :api, defaults: { format: :json } do
  resources :vehicles, only: %i[index show]
end
[0;32mget '/subscribe', to: 'subscribe#index'[0m
[0;32mget '/subscribe', to: 'subscribe#index'[0m
get "/batches.pdf", to: "batches#index"
get "/batches.pdf", to: "batches#index", as: :batches_pdf
