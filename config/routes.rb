Rails.application.routes.draw do
  root "home#index"
end
  get "/health", to: "home#health"
