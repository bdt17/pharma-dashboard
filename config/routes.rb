Rails.application.routes.draw do
  # STATIC LANDING - NO RAILS LAYOUTS EVER
  get '/', to: redirect('/index.html')
  
  get '/up', to: 'rails/health#show', as: :rails_health_check
  
  # All other Rails routes (have blue bar - normal)
  devise_for :users
  resources :batches do
    member do
      get :chain_of_custody
    end
  end
  resources :vehicles
  get '/subscribe', to: 'subscriptions#index'
  get '/health', to: 'health#index'
  get '/dashboard', to: 'dashboard#index'
  get '/gps', to: 'gps#index'
end
