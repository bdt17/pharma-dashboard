Rails.application.routes.draw do
  root "dashboard#index"
  get "/dashboard", to: "dashboard#index"
  # Add your other routes here
end
