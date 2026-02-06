Rails.application.routes.draw do
  root "dashboard#index"
  get "/health", to: "health#index"
  get "/gps/update", to: "gps#update"
  post "/gps/update", to: "gps#update"
  get "/gps/update/stream", to: "gps#stream"
  get "/test-pdf", to: "pdf#test"
  get "/shipments", to: "shipments#index"
  get "/trucks", to: "trucks#index"
  get "/routes", to: "routes#index"
  
  resources :vehicles, only: [:index]
  resources :batches, only: [:index]
end
