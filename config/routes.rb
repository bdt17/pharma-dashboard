Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'  # This requires authentication
  
  get '/public-dashboard', to: 'dashboard#public_index'
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
end
