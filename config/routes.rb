Rails.application.routes.draw do
  root 'dashboard#index'
  
  # test_ui.rb EXPECTED ROUTES 👇
  post '/gps/update', to: 'gps#update'
  get '/gps/update/stream', to: 'gps#stream'
  get '/api/health', to: 'gps#health'
  
  # Test endpoints
  get '/test-pdf', to: 'reports/chain_of_custody#index'
  get '/test-ui', to: 'tests#ui'
  get '/test-rails', to: 'tests#rails'
  get '/test-infosec', to: 'tests#infosec'
end
get '/dashboard/v2', to: 'dashboard#v2'
