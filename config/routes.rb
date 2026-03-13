Rails.application.routes.draw do
  root 'dashboard#index'
  
  devise_for :users
  
  resources :dashboard, only: [:index]
  resources :batches do
    member do
      get :chain_of_custody
    end
  end
  resources :vehicles, only: [:index]
  
  # Health checks
  get '/health', to: 'health#index'
  
  # GPS endpoints
  post '/gps/update', to: 'gps#update'
  get '/gps/update/stream', to: 'gps#stream'
  
  # Test endpoints
  get '/test-pdf', to: 'test_pdf#index'
  get '/shipments', to: 'shipments#index'
  get '/trucks', to: 'trucks#index'
  get '/routes', to: 'routes#index'
  
  # API
  namespace :api do
    get '/health', to: 'health#index'
  end
end
