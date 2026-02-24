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

  # Core resources
  resources :vehicles
  resources :batches do
    member do
      get :custody_report
    end
  end
  resources :sensors
  resources :trackings
  resources :audits

  # GPS tracking
  get '/gps/update', to: 'gps#update'
  get '/gps/stream', to: 'gps#stream'
  get '/api/gps/:id', to: 'sensors#gps'

  # Billing dashboard (Phase 8 Revenue)
  get 'billing', to: 'billing#index'
  get 'billing/plans', to: 'billing#plans'
  post 'billing/subscribe', to: 'billing#subscribe'

  # Stripe Webhooks (Phase 8 Revenue)
  namespace :stripe do
    post 'webhooks', to: 'webhooks#create'
  end

  # Phase 9 IoT APIs
  post '/api/forecast/:vehicle_id', to: 'sensors#forecast'
  post '/api/tamper/:vehicle_id', to: 'sensors#tamper'
  get '/api/vision', to: 'sensors#vision'
end
