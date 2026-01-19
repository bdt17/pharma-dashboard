Rails.application.routes.draw do
  root "dashboard#index"
end
  get "/gps", to: "gps#dashboard"
