Rails.application.routes.draw do
  root "gps#dashboard"
  get "/gps", to: "gps#dashboard"
end
