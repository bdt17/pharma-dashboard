Rails.application.routes.draw do
  root 'dashboard#index'
  devise_for :users
  
  get '/dashboard', to: 'dashboard#index'
  get '/health', to: 'health#index'
  get '/vehicles', to: 'vehicles#index'
  get '/batches', to: 'batches#index'
  
  # GPS (plain paths)
  post '/gps/update', to: 'gps#update'
  get '/gps/update/stream', to: 'gps#stream'
  
  # Quick fixes
  get '/test-pdf', to: 'test_pdf#index'
  get '/subscribe', to: 'subscribe#index'
  get '/shipments', to: 'shipments#index'
  get '/trucks', to: 'trucks#index'
  get '/routes', to: 'routes#index'
end
