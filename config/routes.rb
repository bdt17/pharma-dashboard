Rails.application.routes.draw do
  root 'dashboard#index'
  get 'gps/update'
  get 'gps/stream'
  
  # Thomas IT Pharma GPS API v8.1 - Phoenix AZ
  post '/api/gps', to: 'gps#update'
  get '/api/gps/stream', to: 'gps#stream'
  get '/api/health', to: 'gps#health'
  get "/test-pdf", to: "reports/chain_of_custody#index"
end
