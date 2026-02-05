Rails.application.routes.draw do
  root "dashboard#index"
  
  # Health API
  get '/api/health', to: 'api/health#index'
  
  # GPS APIs  
  get '/gps/vehicles', to: 'gps#vehicles'
  get '/gps/batches', to: 'gps#batches'
end
