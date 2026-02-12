Rails.application.routes.draw do
  get("/", { to: ->(env) { [200, {"Content-Type" => "text/html"}, ["PHARMA DASHBOARD LIVE"]] } })
  get("/health", { to: ->(env) { [200, {"Content-Type" => "application/json"}, [{\"status\":\"ok\"}]] } })
  resources :batches, only: [:index]
  resources :vehicles, only: [:index]
  post "/gps/update"
  get "/gps/stream"
  get "/api/health"
end
