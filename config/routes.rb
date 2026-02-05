Rails.application.routes.draw do
  root 'dashboard#index'
  
  # EXACT test script endpoints
  get '/api/health', to: ->(env) { [200, {"Content-Type" => "application/json"}, ['{"status":"OK"}']] }
  post '/gps_post', to: ->(env) { [201, {"Content-Type" => "application/json"}, ['{"status":"received"}']] }
  get '/gps_stream', to: ->(env) { [200, {"Content-Type" => "text/plain"}, ['GPS Stream']] }
  get '/test_pdf', to: ->(env) { [200, {"Content-Type" => "text/plain"}, ['PDF OK']] }
end
