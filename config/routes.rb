Rails.application.routes.draw do
  root "dashboard#index"
  get '/dashboard', to: 'dashboard#index'
  get '/batches', to: 'dashboard#batches'
  get '/vehicles/:id', to: 'vehicles#show'
end
