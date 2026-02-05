Rails.application.routes.draw do
  root 'dashboard#index'
  get 'dashboard', to: 'dashboard#index'
  
  # Fix health - match test script exactly
  get '/api/health', to: 'healthchecks#index'
  get '/health', to: 'healthchecks#show'
  
  # Fix gps_post - test script POSTs to /gps_post  
  post '/gps_post', to: 'gps#create'
  get '/gps_stream', to: 'gps#stream'
  
  # Fix test_pdf 404
  get '/test_pdf', to: 'pdfs#test'
end
