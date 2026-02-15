Rails.application.routes.draw do
  get '/',          to: 'application#index'
  get '/dashboard', to: 'application#dashboard'
  get '/health',    to: 'application#health'
  get '/vehicles',  to: 'application#vehicles'
  get '/batches',   to: 'application#batches'
  get '/compliance',to: 'application#compliance'
  get '/billing',   to: 'application#billing'
  post '/gps_update', to: 'application#gps_update'
  
  # Devise - COMMENT OUT UNTIL PROPERLY INSTALLED
  # devise_for :users
  
  root to: 'application#index'
  get '/login', to: 'application#login'
  post '/login', to: 'application#login_post'
  get '/logout', to: 'application#logout'

end

  get 'gps/update', to: 'application#gps_update'
  get 'gps/stream', to: 'application#gps_stream'
  get 'api/health', to: 'application#api_health'
