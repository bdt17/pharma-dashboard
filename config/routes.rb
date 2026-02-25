Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  get '/login', to: 'dashboard#login'
  
  # ALL MONEY ENDPOINTS
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'  
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  
  resources :batches do
    member do
      get :custody_report
    end
  end
end
