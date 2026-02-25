Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  
  # ALL MISSING ENDPOINTS
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'  
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  
  resources :batches do
    member do
      get :custody_report
    end
  end
end
