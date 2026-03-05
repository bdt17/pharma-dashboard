Rails.application.routes.draw do
  # Authentication (Devise)
  devise_for :users
  
  # Dashboard & Standard UI
  get 'dashboard', to: 'dashboard#index'
  get 'vehicles', to: 'vehicles#index'
  get 'health', to: 'health#index'
  
  # API endpoints  
  get 'api/health', to: 'api/health#index'
  
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
  
  # Default root
  root 'batches#index'
end
