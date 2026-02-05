Rails.application.routes.draw do
  # Match test script exactly
  root 'dashboard#index'
  get 'dashboard', to: 'dashboard#index'
  get '/api/health', to: 'healthchecks#index'
  get '/health', to: 'healthchecks#show'
  
  # GPS endpoints (test hits POST /gps_post and GET /gps_stream)
  post '/gps_post', to: 'gps#create'
  get '/gps_stream', to: 'gps#stream'
  
  # PDF test
  get '/test_pdf', to: 'pdfs#test'
end
