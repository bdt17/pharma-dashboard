Rails.application.routes.draw do
  # Devise FIRST (before everything else)
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  # Root
  root "home#index"

  # Health checks
  get '/health', to: 'application#health'
  get '/api/health', to: 'application#health'

  # Existing working routes  
  resources :vehicles
  resources :batches do
    member do
      get :custody_report
    end
  end

  # GPS tracking  
  get '/gps/update', to: 'gps#update'
  get '/gps/stream', to: 'gps#stream'

  # Billing dashboard  
  get 'billing', to: 'billing#index'
  get 'billing/plans', to: 'billing#plans'
  post 'billing/subscribe', to: 'billing#subscribe'

  # API ROUTES
  post '/api/forecast/:vehicle_id', to: 'sensors#forecast'
  post '/api/tamper/:vehicle_id', to: 'sensors#tamper'
  get '/api/vision', to: 'sensors#vision'

  # Phase 8+ resources
  resources :sensors
  resources :trackings
  resources :audits
end
