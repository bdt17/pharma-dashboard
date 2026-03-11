Rails.application.routes.draw do
  # Phase 11 Root → Landing (NO blue bar)
  root "landing#index"
  
  get '/up', to: 'rails/health#show', as: :rails_health_check
  devise_for :users
  
  resources :batches do
    member do
      get :chain_of_custody
    end
  end
  
  resources :vehicles
  resources :subscriptions
  get '/subscribe', to: 'subscriptions#index'
  get '/health', to: 'health#index'
  get '/dashboard', to: 'dashboard#index'
  get '/gps', to: 'gps#index'
end
