Rails.application.routes.draw do
  root "home#index"
  get "/health", to: "home#health"
end
