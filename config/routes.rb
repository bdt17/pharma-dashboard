Rails.application.routes.draw do
  root "application#index"
  get "/up", to: -> (env) { [200, {"Content-Type" => "text/plain"}, ["ok"]] }
  get "/dashboard", to: "application#dashboard"
  get "/batches", to: "application#batches"
  get "/pfizer", to: "application#pfizer"
  get "/login", to: "application#login"
  get "/batches/:id/chain_of_custody", to: "application#chain_of_custody"
  get "/batches/:id/label", to: "application#label"
  get "/batches/:id/manifest", to: "application#manifest"
  namespace :api do
    post "/gps", to: "application#gps"
    post "/waymo/:id", to: "application#waymo"
    post "/ai/predict-excursion", to: "application#predict"
    post "/marketplace/bid", to: "application#marketplace"
    post "/auth/signin", to: "application#signin"
    get "/current_user", to: "application#current_user"
    resources :batches, only: [:index, :show]
    resources :audits, only: [:index]
    get "/compliance/report", to: "application#compliance"
  end
  get "/rails/info/properties", to: "application#properties"
end



