Rails.application.routes.draw do
  get 'health', to: 'health#show'
  devise_for :users

  root to: 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  get '/enterprise', to: 'dashboard#index'
  get '/public', to: 'dashboard#public_dashboard'
  
  # Phase 14 endpoints
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  get '/login', to: 'dashboard#login'

  resources :vehicles
  resources :batches do
    member do
      get :custody_report, path: 'custody_report'
    end
  end

  get '/gps/stream', to: 'gps#stream'
  post '/gps/update', to: 'gps#update'

  namespace :api do
    get 'health', to: 'health#show'
  end

  post '/stripe/webhooks', to: 'stripe/webhooks#create'
end
  post '/login', to: 'dashboard#create'
