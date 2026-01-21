Rails.application.routes.draw do
  root "landing#index"
  get "/dashboard", to: "homepage#index"
end
