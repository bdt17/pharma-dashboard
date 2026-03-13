Rails.application.routes.draw do
  root 'home#index'
  get '/health', to: 'health#index'
  get '/vehicles', to: 'home#vehicles'
  get '/batches', to: 'batches#index'
  get '/gps', to: 'home#gps'
  get '/subscribe', to: 'subscribe#index'
  get '/billing', to: 'subscribe#billing'
  
  # Future: batches/:id/chain-of-custody (add later)
  get '/batches/:id/chain-of-custody', to: 'batches#chain_of_custody'
end
