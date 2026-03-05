Rails.application.routes.draw do
  # Auth first
  devise_for :users
  
  # Dashboard
  get 'dashboard', to: 'dashboard#index'
  
  # API Health
  namespace :api do
    get 'health', to: 'health#index'
  end
  
  # GPS IoT endpoints  
  post 'gps/update', to: 'gps#update'
  get 'gps/update/stream', to: 'gps#stream'
  
  # PDF endpoints
  get 'test-pdf', to: 'batches#custody_report', defaults: { id: 1 }
  
  # Core resources
  resources :batches do
    member do
      get 'chain-of-custody', to: 'batches#custody_report'
    end
  end
  
  resources :vehicles, path: 'trucks'
  
  # Default root (batches index)
  root 'batches#index'
end
  get 'vehicles', to: 'vehicles#index'
  get 'vehicles', to: 'vehicles#index'
