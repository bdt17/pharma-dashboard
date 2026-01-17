Rails.application.routes.draw do
  # Devise routes (if present)
  devise_for :users
  
  # Dashboard (PHASE 8)
  root "dashboard#index"
  get "dashboard", to: "dashboard#index", as: :dashboard_index
  
  # Core pharma features
  resources :vehicles, only: [:index, :show]
  resources :batches, only: [:index, :show]
  resources :alerts, only: [:index, :show]
  resources :drivers, only: [:index, :show]
  
  # Analytics
  get "revenue", to: "revenue#index", as: :revenue
  get "compliance", to: "compliance#index", as: :compliance
  
  # API endpoints
  namespace :api do
    resources :vehicles, only: [:index]
    resources :batches, only: [:index]
  end
end
