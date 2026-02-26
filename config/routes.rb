Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'
  
  # Dashboard + core endpoints
  get '/dashboard', to: 'dashboard#index'
  
  # Production endpoints
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  get '/login', to: 'dashboard#login'
  
  # LOGOUT (simple GET)
  get '/logout', to: 'dashboard#logout'
  
  # PDF Custody (simple member route)
  resources :batches, only: [] do
    member do
      get :custody_report
    end
  end
end
