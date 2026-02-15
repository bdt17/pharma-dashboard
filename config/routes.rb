Rails.application.routes.draw do
  devise_for :users
  
  root "dashboard#index"
  get "health", to: "dashboard#health"
  get "vehicles", to: "dashboard#vehicles"
  get "batches", to: "dashboard#batches"
  get "compliance", to: "dashboard#compliance"
  get "billing", to: "dashboard#billing"
end
