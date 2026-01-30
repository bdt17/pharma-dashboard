Rails.application.routes.draw do
  namespace :reports do
    get "chain_of_custody/index"
  end
  get "chain_of_custody/index"
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

get '/dashboard/v2', to: 'dashboard#v2'
get '/chain_of_custody', to: 'chain_of_custody#index', as: :chain_of_custody
get '/test-pdf', to: 'chain_of_custody#index', formats: [:pdf]
end
<<<<<<< HEAD
=======
devise_for :drivers, controllers: { sessions: 'drivers/sessions' }
devise_for :pharmacists, controllers: { sessions: 'pharmacists/sessions' }
devise_for :drivers, path: 'drivers'
devise_for :pharmacists, path: 'pharmacists'

devise_for :drivers, path: 'drivers'
devise_for :pharmacists, path: 'pharmacists'
>>>>>>> abcd72ec (Add Devise login routes)

devise_for :drivers, path: 'drivers'
devise_for :pharmacists, path: 'pharmacists'
