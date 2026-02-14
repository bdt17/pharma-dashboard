Rails.application.routes.draw do
  get '/', to: 'application#index'
  get '/dashboard', to: 'application#dashboard'
  get '/health', to: 'application#health'
  get '/vehicles', to: 'application#vehicles'
  get '/batches', to: 'application#batches'
  post '/gps_update', to: 'application#gps_update'
  
  devise_for :users
  root to: 'application#index'
end
