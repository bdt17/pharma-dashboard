Rails.application.routes.draw do
  root "application#root"
  
  # Devise first (mounts /users/sign_in, /users/sign_out, etc.)
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  
  # API health check
  get "/api/health", to: "api_health#index"
  
  # Dashboard resources
  resources :vehicles
  resources :batches do
    member do
      get :custody_report
    end
  end
  
  # GPS endpoints  
  get "/gps/stream", to: "gps#stream"
  get "/gps/update", to: "gps#update"
  
  # Phase 8 enterprise
  get "/health", to: "health#index"
  get "/billing", to: "billing#index"
  get "/compliance", to: "compliance#index"
end
