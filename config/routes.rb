Rails.application.routes.draw do
  devise_for :users
  
  # Dashboard at ROOT - Devise handles login automatically
  root "dashboard#index"
  
  get "/login", to: "devise/sessions#new"
  get "/dashboard", to: "dashboard#index"
  get "/health", to: "dashboard#health"
  get "/vehicles", to: "dashboard#vehicles"
  get "/batches", to: "dashboard#batches"
  get "/batches/:id/chain_of_custody", to: "dashboard#chain_of_custody"
  get "/billing", to: "dashboard#billing"
  get "/compliance", to: "dashboard#compliance"
  get "/safe", to: "dashboard#safe"
  get "/gps/stream", to: "dashboard#gps_stream"
  get "/api/health", to: "dashboard#api_health"
end
