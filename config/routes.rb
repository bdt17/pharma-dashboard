Rails.application.routes.draw do
  root 'home#index' if defined?(HomeController)
  
  # PROVEN WORKING ROUTES (don't touch)
  resources :vehicles
  resources :batches
  get '/gps/stream', to: 'gps#stream' if defined?(GpsController)
  get '/billing', to: 'billing#index' if defined?(BillingController)
  
  # ADD HEALTH ONLY - simple application controller method
  get '/health', to: 'application#health'
  get '/api/health', to: 'application#health'
end
