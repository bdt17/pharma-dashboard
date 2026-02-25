Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  
  # ALL 8 MONEY ENDPOINTS
  get '/health', to: 'dashboard#health'
  get '/gps/post', to: 'dashboard#gps_post'
  get '/gps/stream', to: 'dashboard#gps_stream'
  get '/test-pdf', to: 'dashboard#test_pdf'
  get '/shipments', to: 'dashboard#shipments'
  get '/trucks', to: 'dashboard#trucks'
  get '/routes', to: 'dashboard#routes'
  get '/batches', to: 'dashboard#batches'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  get '/login', to: 'dashboard#login'
  
  resources :batches do
    member do
      get :custody_report
    end
  end
end
