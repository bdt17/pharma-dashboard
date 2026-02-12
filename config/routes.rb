Rails.application.routes.draw do
  root to: "application#index"
  get "health", to: "application#health"
  get "api/health", to: "application#health"
  get "vehicles", to: "application#vehicles"
  get "batches", to: "application#batches"
  post "gps/update", to: "application#gps_update"
  get "gps/stream", to: "application#gps_stream"
end

get "dashboard", to: "application#dashboard"
