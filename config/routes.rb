Rails.application.routes.draw do
  get "/up", to: "application#health"
  # ... existing routes
end
