Rails.application.routes.draw do
  root "home#index"

  get "health", to: "health#index"
  get "dashboard", to: "dashboard#index"
  
  resources :batches do
    member do
      get :chain_of_custody, defaults: {format: 'pdf'}
    end
  end
  
  get "gps/update", to: "gps#update"
  get "subscribe", to: "subscriptions#new"
  get "stripe/new", to: "stripe#new"
  post "gps/receive", to: "gps#receive"  # ← GPS endpoint
end
