Rails.application.routes.draw do
  get 'health', to: 'health#show'
  devise_for :users

  # Core dashboard routes
  root to: 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  get '/enterprise', to: 'dashboard#index'
  
  # Phase 14 endpoints (ALL INSIDE routes.draw block)
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  get '/login', to: 'dashboard#login'

  # Resources  
  resources :vehicles
  resources :batches do
    member do
      get :custody_report, path: 'custody_report'
    end
  end

  # GPS + API
  get '/gps/stream', to: 'gps#stream'
  post '/gps/update', to: 'gps#update'
  
  namespace :api do
    get 'health', to: 'health#show'
  end

  # Stripe
  post '/stripe/webhooks', to: 'stripe/webhooks#create'
end
