Rails.application.routes.draw do
  root 'home#index'
  
  get "health/index"
  get "/health", to: "health#index"
  get "/api/health", to: "health#index"
  
  resources :vehicles
  resources :batches
  get '/gps/update', to: 'gps#update'
  get '/gps/stream', to: 'gps#stream'
  get '/billing', to: 'billing#index'
  get '/batches/:id/custody_report', to: 'batches#custody_report'
end
