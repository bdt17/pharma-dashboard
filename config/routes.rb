Rails.application.routes.draw do
  root "dashboard#index"
  get "health", to: "health#index"
  get "dashboard", to: "dashboard#index"
  get "batches", to: "batches#index"
  get "batches.pdf", to: "batches#index"
  post "gps/update", to: "gps#update"
  get "subscribe", to: "subscribe#index"
  get "stripe", to: "stripe#index"
end
