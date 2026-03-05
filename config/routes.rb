Rails.application.routes.draw do
  devise_for :users
  
  # Dashboard pages
  get 'dashboard', to: 'dashboard#index'
  get 'vehicles', to: 'vehicles#index'
  get 'health', to: 'health#index'
  get 'login', to: redirect('/users/sign_in')
  
  # API endpoints  
  namespace :api, path: '' do
    get 'health', to: 'health#index'
  end
  
  # GPS IoT
  post 'gps/update', to: 'gps#update'
  get 'gps/update/stream', to: 'gps#stream'
  
  # PDF shortcuts
  get 'test-pdf', to: 'batches#custody_report', defaults: { id: 1 }
  
  # Core resources (keep chain-of-custody PDF)
  resources :batches do
    member do
      get 'chain-of-custody', to: 'batches#custody_report'
    end
  end
  
  # Default root
  root 'batches#index'
end
