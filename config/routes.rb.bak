Rails.application.routes.draw do
  root "home#index"

  get "health", to: "health#index"
  get "dashboard", to: "dashboard#index"
  get "billing", to: "stripe#new"

  resources :batches do
    member do
      get :chain_of_custody, defaults: {format: 'pdf'}
    end
  end

  # GPS endpoints (Queclink GV55)
  get "gps", to: "gps#index"
  get "gps/update", to: "gps#update"
  post "gps/receive", to: "gps#receive"
  
  # Billing
  get "subscribe", to: "subscriptions#new"
  get "stripe/new", to: "stripe#new"
end
