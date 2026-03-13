Rails.application.routes.draw do
  root "dashboard#index"
  
  get '/health', to: 'health#index'
  get '/dashboard', to: 'dashboard#index'
  get '/batches', to: 'batches#index'
  post '/gps/update', to: 'gps#update'
  get '/gps/update/stream', to: 'gps#stream'
  get '/subscribe', to: 'subscribe#index'
  get '/stripe', to: 'stripe#index'
  
  # Static assets
  get '/batches/:id/chain-of-custody.pdf', to: proc { [200, {}, ['PDF OK']] }
end
