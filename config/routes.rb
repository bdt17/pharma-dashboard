Rails.application.routes.draw do
  devise_for :users, path: '', path_names: { sign_in: 'login', sign_out: 'logout' }
  
  # Public health/monitoring endpoints
  root 'dashboard#index'
  get '/public-dashboard', to: 'dashboard#public_index'
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'

  # Authenticated dashboard pages  
  authenticate :user do
    get '/trucks', to: 'dashboard#trucks'
    get '/shipments', to: 'dashboard#shipments'
    get '/routes', to: 'dashboard#routes'
    # REMOVED: get '/login', to: 'dashboard#login'  ❌
  end

  # GPS API 
  namespace :api do
    namespace :v1 do
      post 'gps/update', to: 'gps#update'
      get  'gps/stream', to: 'gps#stream'
      get  'health', to: 'health#show'
    end
  end

  # Batch custody reports
  resources :batches, only: [:index] do
    member do
      get :custody_report
    end
  end
end
