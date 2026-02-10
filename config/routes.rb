Rails.application.routes.draw do
  devise_for :users
  root "dashboard#index"
  get "/health", to: "dashboard#health"
  get "/vehicles", to: "dashboard#vehicles"    # ✅ Fixed 500→200
  get "/batches", to: "dashboard#batches"
  get "/batches/:id/chain_of_custody", to: "dashboard#chain_of_custody"
  get "/billing", to: "dashboard#billing"
  get "/compliance", to: "dashboard#compliance"  # ← ADD THIS
  get "/safe", to: "dashboard#safe"
  get "/gps/stream", to: "dashboard#gps_stream"
  get "/api/health", to: "dashboard#api_health"
end
