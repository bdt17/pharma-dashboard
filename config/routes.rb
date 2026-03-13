Rails.application.routes.draw do
  root 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  get '/health', to: 'health#index'
  get '/batches', to: 'batches#index'
  get '/vehicles', to: 'vehicles#index'
  post '/gps/update', to: 'gps#update'
  get '/gps/update/stream', to: 'gps#stream'
  get '/subscribe', to: 'subscribe#index'
  get '/stripe', to: 'stripe#index'
  devise_for :users
end
