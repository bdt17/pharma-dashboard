Rails.application.routes.draw do
  # Root
  root "home#index"

  # Authentication (Devise)
  devise_for :users

  # Pages (non‑API)
  get "/dashboard", to: "dashboard#index"
  get "/vehicles", to: "vehicles#index"
  get "/batches",  to: "batches#index"
  get "/subscribe", to: "subscribe#index"
  get "/billing",   to: "billing#index"
  get "/compliance", to: "compliance#index"
  get "/temperature_log", to: "temperature_log#index"
  get "/stripe_success", to: "stripe_success#index"

  # Health check - FIXES 500 ERROR
  get "/health", to: "application#health"

  # PDF / CoC routes - ALL WORKING ✅
  get "/batches/:id/chain-of-custody.pdf", to: "batches#coc_pdf", as: :batch_coc_pdf
  get "/batches.pdf", to: "batches#index", defaults: { format: :pdf }

  # GPS routes - Queclink GV55 IoT
  get   "/gps",          to: "gps#index"
  get   "/gps/stream",   to: "gps#stream"
  post  "/gps/update",   to: "gps#update" 
  post  "/gps/receive",  to: "gps#receive"  # TCP endpoint for GV55

  # API namespace (JSON only)
  namespace :api, defaults: { format: :json } do
    resources :batches, only: %i[index show]
    resources :vehicles, only: %i[index show]
    get "/health", to: "health#index"
  end

  # Debug / admin helpers
  get "/debug/batches", to: "debug_batches#index"
end
