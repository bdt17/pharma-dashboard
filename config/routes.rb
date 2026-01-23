Rails.application.routes.draw do
  # BULLETPROOF ROOT - use dashboard (already working)
  root 'dashboard#index'

  # Keep all working APIs
  get '/api/health', to: 'health#show'
  post '/api/gps', to: 'gps#update'
  get '/reports/chain-of-custody/:id', to: 'reports#chain_of_custody', as: :chain_of_custody
  get '/batches', to: 'batches#index'
  get '/vehicles/:id', to: 'vehicles#show'
end
