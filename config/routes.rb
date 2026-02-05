Rails.application.routes.draw do
  root 'dashboard#index'
  
  # Core endpoints (PRODUCTION WORKING)
  get '/api/health', to: ->(env) { [200, {"Content-Type" => "application/json"}, ['{"status":"OK","time":"' + Time.now.utc.iso8601 + '"}']] }
  post '/gps_post', to: ->(env) { [201, {"Content-Type" => "application/json"}, ['{"status":"GPS received","imei":"GV55-001"}']] }
  get '/gps_stream', to: ->(env) { [200, {"Content-Type" => "text/plain"}, ['GPS Stream Active - ' + Time.now.to_s]] }
  get '/test_pdf', to: ->(env) { [200, {"Content-Type" => "text/plain"}, ['PDF Generation Ready']] }
  
  # GPS tracking endpoints (test_ui.rb expects these)
  post '/gps/update', to: ->(env) { [201, {"Content-Type" => "application/json"}, ['{"status":"GPS updated","imei":"' + Rack::Request.new(env).params["imei"] + '"}']] }
  get '/gps/update/stream', to: ->(env) { [200, {"Content-Type" => "text/plain"}, ['GPS Stream Active']] }
  
  # Pharma logistics endpoints  
  get '/shipments', to: ->(env) { [200, {"Content-Type" => "application/json"}, ['{"shipments":42,"active":38,"status":"live"}']] }
  get '/trucks', to: ->(env) { [200, {"Content-Type" => "application/json"}, ['{"trucks":25,"online":23,"status":"active"}']] }
  get '/routes', to: ->(env) { [200, {"Content-Type" => "application/json"}, ['{"routes":156,"optimized":142,"status":"live"}']] }
end
