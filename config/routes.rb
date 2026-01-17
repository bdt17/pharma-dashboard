Rails.application.routes.draw do
  root "dashboard#index"
  get "dashboard", to: "dashboard#index"
  get "pfizer",    to: "dashboard#pfizer"

  namespace :api do
    post "/gps",                 to: "gps#create"
    post "/waymo/:id",           to: "waymo#create" 
    post "/ai/predict-excursion", to: "ai#create"
    post "/marketplace/bid",     to: "marketplace#create"
  end
end
