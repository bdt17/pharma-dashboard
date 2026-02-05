Rails.application.routes.draw do
  # Main dashboard (root)
  root "dashboard#index"

  # Phase 1: Core health
  get "/api/health", to: "api/health#index"

  # Phase 2: GPS tracking JSON
  get "/gps/vehicles", to: "gps#vehicles"
  get "/gps/batches",  to: "gps#batches"
end
