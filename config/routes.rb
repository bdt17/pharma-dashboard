Rails.application.routes.draw do
  devise_for :users
  
  root "dashboard#index"
  get "health", to: "dashboard#health"
  get "vehicles", to: "dashboard#vehicles"
  get "batches", to: "dashboard#batches"
  get "compliance", to: "dashboard#compliance"
  get "billing", to: "dashboard#billing"
  
  # Phase 2 GPS endpoints
  resources :gps, only: [] do
    collection do
      post :update
      get :stream
    end
  end
  
  # Phase 3 API
  get "/api/health", to: "dashboard#api_health"
end
