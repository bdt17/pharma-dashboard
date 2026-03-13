Rails.application.routes.draw do
  root "dashboard#index"
  
  # Public endpoints
  get "health", to: "health#index"
  get "dashboard", to: "dashboard#index"
  get "batches", to: "batches#index"
  get "batches.pdf", to: "batches#index"
  get "batches/:id/chain-of-custody.pdf", to: "batches#show"
  post "gps/update", to: "gps#update"
  get "gps", to: "gps#index"
  get "subscribe", to: "subscribe#index"
  get "stripe", to: "stripe#index"
  
  # Devise routes (login)
  devise_for :users
end
