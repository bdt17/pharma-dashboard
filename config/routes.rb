Rails.application.routes.draw do
  get "home/index"
  get "home/health"
  get "home/dashboard"
  # DEVISE FIRST (no custom names = no conflicts)
  devise_for :users
  
  # PUBLIC LANDING PAGE
  root "home#index"                    # / → PharmaTransport 2.0 landing
  
  # PUBLIC HEALTH CHECK
  get 'health', to: 'home#health'      # /health → Render monitoring
  
  # PROTECTED DASHBOARDS (login required)
  get 'dashboard', to: 'home#dashboard'
  get 'vehicles', to: 'vehicles#index'
  get 'batches', to: 'batches#index'
  get 'compliance', to: 'compliance#index'
  get 'billing', to: 'billing#index'
  
  # API (Phase 2)
  post '/gps/update', to: 'home#gps_update'
end

