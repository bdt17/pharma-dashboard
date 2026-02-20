Rails.application.routes.draw do
  # Devise first (mounts /users/sign_in, /users/sign_out, etc.)
  devise_for :users

  # Public health check (for Render + your test script)
  get "health", to: "dashboard#health"

  # Root + protected dashboard routes
  root "dashboard#index"
  get "vehicles", to: "dashboard#vehicles"
  get "batches", to: "dashboard#batches"
  get "compliance", to: "dashboard#compliance"
  get "billing", to: "dashboard#billing"

  # Phase 2 GPS endpoints (ActionCable + ingest)
  resources :gps, only: [] do
    collection do
      post :update
      get :stream
    end
  end

  # Phase 8: Chain-of-Custody PDF reports
  resources :batches, only: [] do
    member do
      get :custody_report, to: 'custody_reports#show', as: :custody_report
    end
  end

  # Phase 3: Public API (no auth for health, test script goes green)
  namespace :api do
    get :health, to: "health#show"
  end

  # Legacy API endpoint (your test script expects /api/health)
  get "/api/health", to: "api_health#index"
end
