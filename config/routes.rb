Rails.application.routes.draw do
  devise_for :users
  # TEMP: User routes disabled for Render
  # devise_for :users
  
  root "dashboard#index"
  get '/health', to: 'health#show'
  resources :vehicles, only: :index
  resources :batches, only: :index
  get '/compliance', to: 'compliance#index'
  get '/billing', to: 'billing#index'
end
