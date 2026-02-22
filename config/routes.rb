Rails.application.routes.draw do
  # Landing page
  root "application#root"
  
  # Core enterprise endpoints - EXPLICIT routes
  get "/health", to: "health#index"
  get "/api/health", to: "api_health#index"
  get "/vehicles", to: "vehicles#index"
  get "/batches", to: "batches#index"
  get "/billing", to: "billing#index"
  
  # GPS endpoints  
  get "/gps/stream", to: "gps#stream"
  post "/gps/update", to: "gps#update"
  
  # Sign-up (no Devise crash)
  get "/sign-up", to: "application#signup"
end
