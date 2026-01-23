Rails.application.routes.draw do
  get '/api/health', to: 'health#show'
  post '/api/gps', to: 'gps#update'
  get '/reports/chain-of-custody/:id', to: 'reports#chain_of_custody', as: :chain_of_custody
  get "/batches", to: "batches#index"
# #   # devise_for :users  # ← COMMENTED OUT (no User model)
  root "dashboard#index"
  get '/dashboard', to: 'dashboard#index'
  get '/batches', to: 'dashboard#batches'
  get '/vehicles/:id', to: 'vehicles#show'
end
