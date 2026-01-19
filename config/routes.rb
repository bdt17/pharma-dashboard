Rails.application.routes.draw do
  root "landing#index"
  get "/gps", to: "gps#dashboard"
end
