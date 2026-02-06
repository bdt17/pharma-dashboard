Rails.application.routes.draw do
  get "health/index"
  get "gps/update"
  get "gps/stream"
  get "dashboard/index"
  get "routes/index"
  get "trucks/index"
  get "shipments/index"
  get "pdf/test"
  root "dashboard#index"
  get "/health", to: "health#index"
  post "/gps/update", to: "gps#update"
  get "/gps/stream", to: "gps#stream"
  
  resources :vehicles, only: [:index]
  resources :batches, only: [:index]
end

  get 'dashboard', to: 'dashboard#index'
  get 'gps/update', to: 'gps#update'
  get 'gps/update/stream', to: 'gps#stream'
  get 'test-pdf', to: 'pdf#test'
  get 'shipments', to: 'shipments#index'
  get 'trucks', to: 'trucks#index'
  get 'routes', to: 'routes#index'
