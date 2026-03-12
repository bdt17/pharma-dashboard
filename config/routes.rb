Rails.application.routes.draw do
  root "landing#index"
  
  # Health
  get '/up', to: 'rails/health#show'
  get '/health', to: 'health#index'
  
  # Auth
  devise_for :users
  
  # Revenue
  get '/subscribe', to: 'subscriptions#index'
  get '/stripe/new', to: 'stripe#new'
  get '/stripe/success', to: 'stripe#success'
  get '/billing', to: 'billing#index'
  
  # Dashboard
  get '/dashboard', to: 'dashboard#index'
  
  # PDF MONEY MAKER - EXACT ROUTE
  resources :batches do
    member do
      get :chain_of_custody, defaults: {format: 'pdf'}
    end
  end
  
  resources :vehicles
  resources :gps, only: [:index]
end
