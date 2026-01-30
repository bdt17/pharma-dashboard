Rails.application.routes.draw do
  # Phase 2 GPS Dashboard
  get '/vehicles', to: 'vehicles#index', as: :vehicles
  
  # Phase 3 FDA Compliance (future)
  get '/compliance', to: 'compliance#index', as: :compliance
  
  # Existing Phase 1 routes (keep these)
  root 'dashboard#index'
  get '/api/health', to: 'health#index'
  
  # Devise (drivers)
  devise_for :drivers
  
  # Resources
  resources :batches
  resources :vehicles
end
