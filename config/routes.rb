Rails.application.routes.draw do
  root "dashboard#index"
  get "dashboard", to: "dashboard#index", as: :dashboard_index
  
  resources :vehicles, only: [:index, :show]
  resources :batches, only: [:index, :show] 
  resources :alerts, only: [:index, :show]
  get "revenue", to: "revenue#index", as: :revenue
end
