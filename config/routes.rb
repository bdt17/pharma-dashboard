Rails.application.routes.draw do
  get "gps/update"
  get "gps/stream"
  root 'dashboard#index'
  
  # Thomas IT GPS API - Phase 2 (Phoenix AZ)
  post '/api/gps', to: 'gps#update'
  get '/api/gps/stream', to: 'gps#stream'
  
  # Health check (Phase 3)
  get '/api/health', to: 'gps#health'
end
