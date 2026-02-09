Rails.application.routes.draw do
  root "dashboard#index"
  get "/health", to: "dashboard#health"
  get "/vehicles", to: "dashboard#vehicles"
  get "/batches", to: "dashboard#batches"
  get "/batches/:id/chain_of_custody", to: "dashboard#chain_of_custody"
  get "/billing", to: "dashboard#billing"
  get "/safe", to: "dashboard#safe"
  get "/gps/stream", to: "dashboard#gps_stream"
  get "/api/health", to: "dashboard#api_health"
end

get 'login', to: 'sessions#new'
post 'login', to: 'sessions#create'
delete 'logout', to: 'sessions#destroy', as: 'logout'
