Rails.application.routes.draw do
  # Landing page
  root "application#root"
  
  # Explicit API routes (bypass resources)
  get "/health", to: "health#index"
  get "/api/health", to: "api_health#index"
  get "/vehicles", to: "vehicles#index"
  get "/batches", to: "batches#index"
  get "/billing", to: "billing#index"
  
  # GPS endpoints
  get "/gps/stream", to: "gps#stream"
  post "/gps/update", to: "gps#update"
  
  # DEBUG routes
  get "/debug/test", to: proc { [200, {"Content-Type" => "text/plain"}, ["Phase 8 LIVE"]] }
end
