Rails.application.routes.draw do
  get "reports/pdf"
  get "health/index"
  get "home/index"
  # Root
  root "home#index"
  
  # Health checks
  get '/health', to: 'application#health'
  get '/api/health', to: 'application#health'
  
  # Existing working routes
  resources :vehicles
  resources :batches do
    member do
      get :custody_report
    end
  end
  
  # GPS tracking  
  get '/gps/update', to: 'gps#update'
  get '/gps/stream', to: 'gps#stream'
  
  # Enterprise
  get '/billing', to: 'billing#index'
end
  member do
    get :pdf, action: :pdf
  end
