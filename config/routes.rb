Rails.application.routes.draw do
  get "/batches", to: "batches#index"
 #  devise_for :users
  root "dashboard#index"
  get '/dashboard', to: 'dashboard#index'
  get '/batches', to: 'dashboard#batches'
  get '/vehicles/:id', to: 'vehicles#show'
end
