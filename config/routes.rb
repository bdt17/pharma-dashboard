Rails.application.routes.draw do
  root 'dashboard#index'
  get '/health', to: 'health#show'
  
  # GPS endpoints
  post '/gps/update', to: 'gps#update'
  get '/gps/stream', to: 'gps#stream'
  
  # Pharma features
  resources :batches do
    member do
      get :chain_of_custody
    end
  end
  
  resources :vehicles
  
  # Billing (Phase 9 prep)
  get '/billing', to: 'billing#index'
  
  # Devise (safe - skip if broken)
  begin
    devise_for :users
  rescue
  end
end

  get '/billing', to: 'billing#index', as: :billing
  get '/billing/success', to: 'billing#success', as: :billing_success
  post '/billing/webhook', to: 'billing#create'
