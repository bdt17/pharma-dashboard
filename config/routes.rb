Rails.application.routes.draw do
  get '/' => proc { [200, {'Content-Type' => 'text/html'}, ['PHARMA DASHBOARD v8.1']] }
  get '/health' => proc { [200, {'Content-Type' => 'application/json'}, ['{"status":"ok"}']] }
  get '/api/health' => proc { [200, {'Content-Type' => 'application/json'}, ['{"status":"ok"}']] }
  get '/vehicles' => proc { [200, {'Content-Type' => 'application/json'}, ['[]']] }
  get '/batches' => proc { [200, {'Content-Type' => 'application/json'}, ['[]']] }
  post '/gps/update' => proc { [200, {'Content-Type' => 'application/json'}, ['{"received":true}']] }
  get '/gps/stream' => proc { [200, {'Content-Type' => 'text/plain'}, ['']] }
end
