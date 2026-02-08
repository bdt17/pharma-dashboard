Rails.application.routes.draw do
  root 'dashboard#index'
  get '/health', to: 'health#show'
  
  post '/gps/update', to: 'gps#update'
  get '/gps/stream', to: 'gps#stream'
  
  resources :vehicles
  resources :batches do
    member do
      get :chain_of_custody
    end
  end
  
  get '/billing', to: 'billing#index'
  get '/billing/success', to: 'billing#success'
end
