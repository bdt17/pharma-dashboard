Rails.application.routes.draw do
  namespace :reports do
    get "chain_of_custody/index"
  end
  get "chain_of_custody/index"
  root 'dashboard#index'

  # test_ui.rb EXPECTED ROUTES 👇
  post '/gps/update', to: 'gps#update'
  get '/gps/update/stream', to: 'gps#stream'
  get '/api/health', to: 'health#show'  # ← FIXED: was gps#health

  # Test endpoints
  get '/test-pdf', to: 'reports/chain_of_custody#index'
  get '/test-ui', to: 'tests#ui'
  get '/test-rails', to: 'tests#rails'
  get '/test-infosec', to: 'tests#infosec'

  get '/dashboard/v2', to: 'dashboard#v2'
  get '/chain_of_custody', to: 'chain_of_custody#index', as: :chain_of_custody
  get '/test-pdf', to: 'chain_of_custody#index', formats: [:pdf]

  # DISABLED - Add models first!
  # devise_for :drivers, path: 'drivers'
  # devise_for :pharmacists, path: 'pharmacists'
end
get '/vehicles', to: 'vehicles#index'
