Rails.application.routes.draw do
  # Health + Devise
  get 'health', to: 'health#show'
  devise_for :users

  # Core dashboard  
  root to: 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'

  # Phase 14-16 endpoints (ALL working)
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches' 
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  get '/login', to: 'dashboard#login'

  # NEW - Missing Phase 16 endpoints
  get '/trucks', to: 'dashboard#vehicles'      # Alias for trucks
  get '/shipments', to: 'dashboard#batches'    # Alias for shipments  
  get '/routes', to: 'dashboard#routes'        # Route planner
  get '/test-pdf', to: 'batches#test_pdf'      # PDF test

  # GPS endpoints (your LIVE tests)
  post '/gps/update', to: 'gps#update'
  get '/gps/stream', to: 'gps#stream'
  get '/gps/update/stream', to: 'gps#stream'   # Your exact test URL

  # API namespace
  namespace :api do
    get 'health', to: 'health#show'
  end

  # Resources
  resources :vehicles
  resources :batches do
    member do
      get :custody_report, path: 'custody_report'
      get :test_pdf
    end
  end

  post '/stripe/webhooks', to: 'stripe/webhooks#create'
end
