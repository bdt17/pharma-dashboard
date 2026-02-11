Rails.application.routes.draw do
  devise_for :users
  root "dashboard#index"
  get "/vehicles", to: "dashboard#vehicles"
  get "/batches", to: "dashboard#batches"
  get "/compliance", to: "dashboard#compliance"
end
