Rails.application.routes.draw do
#   devise_for :users
  
  root "dashboard#index"
  get "health", to: "dashboard#health"
  get "vehicles", to: "dashboard#vehicles"
  get "batches", to: "dashboard#batches"
  get "compliance", to: "dashboard#compliance"
  get "billing", to: "dashboard#billing"
 post '/gps/update', to: 'dashboard#gps_update'
 get '/gps/stream', to: 'dashboard#gps_stream'
 get '/api/health', to: 'dashboard#api_health'
end
