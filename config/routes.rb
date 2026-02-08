Rails.application.routes.draw do
  root "dashboard#index"
  
  get  "/health", to: "health#index"
  get  "/api/health", to: "health#index"
  post "/gps/update", to: "gps#update"  
  get  "/gps/stream", to: "gps#stream"
  
  resources :vehicles, only: [:index]
  resources :batches, only: [:index]
  get "/stripe/checkout", to: "stripe/checkout#new"
end

resources :billing, only: [:index, :create] do
  collection do
    get :success
    get :cancel
  end
end
