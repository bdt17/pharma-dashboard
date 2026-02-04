Rails.application.routes.draw do
  get '/vehicles', to: 'vehicles#index'
  root 'dashboard#index'
  get '/api/health', to: 'health#index'
end
get '/health', to: 'healthchecks#show'
get "/health", to: "healthchecks#show"
