Rails.application.routes.draw do
  get "/" => lambda { [200, {"Content-Type" => "text/html"}, ["PHARMA DASHBOARD v8.1 LIVE"]] }
  get "/health" => lambda { [200, {"Content-Type" => "application/json"}, ['{"status":"ok"}']] }
  get "/api/health" => lambda { [200, {"Content-Type" => "application/json"}, ['{"status":"ok"}']] }
  get "/vehicles" => lambda { [200, {"Content-Type" => "application/json"}, ['[]']] }
  get "/batches" => lambda { [200, {"Content-Type" => "application/json"}, ['[]']] }
  post "/gps/update" => lambda { [200, {"Content-Type" => "application/json"}, ['{"received":true}']] }
  get "/gps/stream" => lambda { [200, {"Content-Type" => "text/plain"}, [""]] }
end
