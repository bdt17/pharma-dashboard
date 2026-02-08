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
  get '/billing', to: 'billing#index'
  get '/billing/success', to: 'billing#success'
end
