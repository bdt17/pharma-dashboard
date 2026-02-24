Rails.application.routes.draw do
  # Devise FIRST (before everything else)
  devise_for :users

  # Root + Core endpoints (public + dual-mode) - Phase 8 LIVE
  root to: "dashboard#index"
  get '/public', to: 'dashboard#public_dashboard'
  get '/enterprise', to: 'dashboard#index'
  
  # Public revenue/health endpoints (test_ui.rb green)
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/billing/plans', to: 'billing#plans'
  post '/billing/subscribe', to: 'billing#subscribe'
  
  # Resources (protected by controller before_action)
  resources :vehicles
  resources :batches do
    member do
      get :custody_report, path: 'custody_report'
    end
  end
  
  # Stripe Webhooks (Phase 8 Revenue - KEEP)
  post '/stripe/webhooks', to: 'stripe/webhooks#create'
end
