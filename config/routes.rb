Rails.application.routes.draw do
  root "batches#index"
  get "health", to: "health#index"
  get "dashboard", to: "dashboard#index"
  get "batches", to: "batches#index"
  get "batches.pdf", to: "batches#index"
  get "batches/:id/chain-of-custody.pdf", to: "batches#index"
  post "gps/update", to: "gps#update"
  get "gps", to: "gps#index"
  get "subscribe", to: "subscribe#index"
  get "stripe", to: "stripe#index"
end
