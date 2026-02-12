root "dashboard#index"
get 'health', to: ->(env) { [200, {'Content-Type' => 'application/json'}, ['{"status":"ok","uptime":123}']] }
get 'gps/update', to: ->(env) { [200, {'Content-Type' => 'application/json'}, ['{"received":true,"imei":"GV55-001"}']] }
get 'test-pdf', to: ->(env) { [200, {'Content-Type' => 'text/plain'}, ['PDF endpoint ready']] }
get 'shipments', to: ->(env) { [200, {'Content-Type' => 'application/json'}, ['[{"lot":"LOT-PHARMA-20260211"}]']] }
get 'trucks', to: ->(env) { [200, {'Content-Type' => 'application/json'}, ['[{"name":"AZ Pharma-001"}]']] }
get 'routes', to: ->(env) { [200, {'Content-Type' => 'application/json'}, ['[{"id":1}]']] }
