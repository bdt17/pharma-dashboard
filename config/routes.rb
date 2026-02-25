Rails.application.routes.draw do
  get 'health', to: 'health#show'

  devise_for :users, controllers: { sessions: 'sessions' }

  root to: 'dashboard#index'
  
  # All Phase 14-16 endpoints
  get 'dashboard', to: 'dashboard#index'
  get 'enterprise', to: 'dashboard#index'
  get 'public', to: 'dashboard#public_dashboard'
  get 'vehicles', to: 'dashboard#vehicles'
  get 'batches', to: 'dashboard#batches'
  get 'billing', to: 'dashboard#billing'
  get 'compliance', to: 'dashboard#compliance'
  get 'login', to: 'dashboard#login'  # Plain text for test_login.sh
  get 'trucks', to: 'dashboard#trucks'
  get 'shipments', to: 'dashboard#shipments'
  get 'routes', to: 'dashboard#routes'

  # GPS endpoints
  post 'gps/update', to: 'gps#update'
  get 'gps/stream', to: 'gps#stream'

  # API
  namespace :api do
    get 'health', to: 'health#show'
  end

  # Resources
  resources :vehicles
  resources :batches do
    member do
      get 'custody_report'
      get 'test_pdf'
    end
  end

  # Stripe
  post 'stripe/webhooks', to: 'stripe/webhooks#create'
end
