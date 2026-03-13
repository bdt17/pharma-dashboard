Rails.application.routes.draw do
  root "dashboard#index"
  get "health", to: "health#index"
  get "dashboard", to: "dashboard#index"
  get "batches", to: "batches#index"
  get "batches.pdf", to: "batches#index"
  get "subscribe", to: "subscribe#index"
  get "billing", to: "billing#index"
end
