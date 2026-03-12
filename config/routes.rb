Rails.application.routes.draw do
  root "home#index"

  get "health", to: "health#index"
  get "dashboard", to: "dashboard#index"

  resources :batches do
    member do
      get :chain_of_custody, defaults: {format: 'pdf'}
    end
  end

  # GPS endpoints
  get "gps", to: "gps#index"
  get "gps/update", to: "gps#update"
  post "gps/receive", to: "gps#receive"
  
  # Billing endpoints
  get "subscribe", to: "subscriptions#new"
  get "stripe/new", to: "stripe#new"

  # Status pages
  get "status", to: "health#index"
end
get "billing", to: "stripe#new"
