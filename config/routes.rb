Rails.application.routes.draw do
  root "application#root"
  
  get "/api/health", to: "api_health#index"
  get "/health", to: "health#index"
  
  # Dashboard - index actions  
  resources :vehicles, only: [:index]
  resources :batches, only: [:index] do
    member do
      get :custody_report
    end
  end
  
  # GPS endpoints
  get "/gps/stream", to: "gps#stream"
  get "/gps/update", to: "gps#update"
  
  # Enterprise
  get "/billing", to: "billing#index"
end
get "/sign-up", to: "application#signup"
