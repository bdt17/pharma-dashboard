Rails.application.routes.draw do
  get "billing/index"
  devise_for :users
  root "dashboard#index"
  
  # ALL FUNCTIONAL ROUTES
  get "/vehicles", to: "dashboard#vehicles"
  get "/batches", to: "dashboard#batches" 
  get "/compliance", to: "dashboard#compliance"
  get "/gps", to: "dashboard#gps"
  get "/billing", to: "billing#index"


end
