Rails.application.routes.draw do
  # Authentication
  devise_for :users
  
  # Dashboard & Pages
  root 'batches#index'
  get 'dashboard', to: 'dashboard#index'
  get 'vehicles', to: 'vehicles#index'
  get 'health', to: 'health#index'
  get 'billing', to: 'billing#index'
  get 'compliance', to: 'compliance#index'
  
  # API
  get 'api/health', to: 'api/health#index'
  
  # GPS IoT
  post 'gps/update', to: 'gps#update'
  get 'gps/update/stream', to: 'gps#stream'
  
  # PDF
  get 'test-pdf', to: 'batches#custody_report', defaults: { id: 1 }
  
  # Core resources
  resources :batches do
    member do
      get 'chain-of-custody', to: 'batches#custody_report'
    end
  end
end
