Rails.application.routes.draw do
  root "home#index"
end
get "/dashboard", to: "dashboard#index"
