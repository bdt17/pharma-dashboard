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

  # Health / status (HTML)
  get "/health", to: "application_health#index"

  # PDF / CoC routes  
  get "/batches.pdf", to: "batches#index"  # Fixed: explicit path
  get "/coc_pdf",  to: "coc_pdf#index"
  get "/batches/:id/chain-of-custody.pdf", to: "batches#coc_pdf", as: :batch_coc_pdf
  get "/coc_api",  to: "coc_api#index"

  # Debug / admin helpers
  get "/debug/batches", to: "debug_batches#index"

  # API namespace (JSON only)
  namespace :api, defaults: { format: :json } do
    resources :batches, only: %i[index show]
    resources :vehicles, only: %i[index show]
    get "/health", to: "health#index"
  end
end
