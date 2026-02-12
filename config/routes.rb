Rails.application.routes.draw do
  root "application#index"
  get "/dashboard", to: "application#dashboard"
  get "/health", to: "application#health"
  get "/vehicles", to: "application#vehicles"
  get "/batches", to: "application#batches"
  post "/gps/update", to: "application#gps_update"
end
