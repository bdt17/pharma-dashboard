Rails.application.routes.draw do
  get "home/index"
  # Landing page (public - root)
  root 'home#index'

  # Dashboard (separate route)
  get '/dashboard', to: 'dashboard#index'

  # API endpoints (PRODUCTION WORKING)
  get '/api/health', to: 'health#show'
  post '/api/gps', to: 'gps#update'

  # FDA Reports
  get '/reports/chain-of-custody/:id', to: 'reports#chain_of_custody', as: :chain_of_custody

  # Batches
  get '/batches', to: 'batches#index'

  # Vehicles
  get '/vehicles/:id', to: 'vehicles#show'
end
