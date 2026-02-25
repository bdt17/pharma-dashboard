Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  
  resources :batches do
    member do
      get :custody_report
    end
  end
  
  # Public APIs
  get '/dashboard/vehicles', to: 'dashboard#vehicles'
  get '/dashboard/batches', to: 'dashboard#batches'  
  get '/dashboard/health', to: 'dashboard#health'
end
