Rails.application.routes.draw do
  get 'health', to: 'application#health'
  get 'vehicles', to: 'application#vehicles'
  get 'batches', to: 'application#batches'
  get 'compliance', to: 'application#compliance'
  get 'billing', to: 'application#billing'
  post 'gps/update', to: 'application#gps_update'    # <- FIXED: was gps_update
  get 'gps/stream', to: 'application#gps_stream'
  get 'api/health', to: 'application#api_health'
  
  root 'application#index'
end
