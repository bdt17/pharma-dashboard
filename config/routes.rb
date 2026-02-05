Rails.application.routes.draw do
  root "dashboard#index"
end

namespace :api do
  get "health", to: "health#index"
  get "vehicles", to: "vehicles#index"
  get "batches", to: "batches#index"
end

resources :gps, only: [] do
  collection do
    get :vehicles
    get :batches
  end
end
