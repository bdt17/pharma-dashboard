Rails.application.routes.draw do
  root 'home#index'
  get '/health', to: 'health#index'
  get '/vehicles', to: 'home#vehicles'
  get '/batches', to: 'batches#index'
  get '/gps', to: 'home#gps'
  get '/subscribe', to: 'subscribe#index'
  get '/billing', to: 'subscribe#billing'
  
  # Devise (if installed)
  devise_for :users
  
  # API/Chain of Custody
  get '/batches/:id/chain-of-custody', to: 'batches#chain_of_custody'
end
