Rails.application.routes.draw do
  root 'dashboard#index'
  get 'gps/update'
  get 'gps/stream'
  
  # Thomas IT Pharma Transport GPS API v8.1
  namespace :api do
    post '/gps', to: 'gps#update'
    get '/gps/stream', to: 'gps#stream'
    get '/health', to: 'gps#health'
  end
end
