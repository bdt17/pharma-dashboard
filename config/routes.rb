Rails.application.routes.draw do
  root "dashboard#index"
  
  # API Health Check
  namespace :api do
    get "health", to: "health#index"
  end
  
  # GPS Endpoints  
  get "/gps/vehicles", to: "gps#vehicles"
  get "/gps/batches", to: "gps#batches"
end
