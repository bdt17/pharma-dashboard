Rails.application.routes.draw do
  root 'dashboard#index'
  get 'gps/update'
  get 'gps/stream'
  
  # PHASE 2 GPS API
  post '/api/gps', to: 'gps#update'
  get '/api/gps/stream', to: 'gps#stream'
  get '/api/health', to: 'gps#health'
end
