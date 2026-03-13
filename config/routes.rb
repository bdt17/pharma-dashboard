Rails.application.routes.draw do
  root 'home#index'
  get '/dashboard', to: 'home#index'
  get '/health', to: 'health#index'
  get '/vehicles', to: 'home#vehicles'
  get '/batches', to: 'batches#index'
  get '/gps', to: 'home#gps'
  get '/subscribe', to: 'subscribe#index'
  get '/billing', to: 'subscribe#billing'
end
