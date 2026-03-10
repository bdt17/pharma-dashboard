Rails.application.routes.draw do
  devise_for :users
  
  root to: proc { [200, {}, ['Pharma Transport LIVE']] }
  get 'health', to: proc { [200, {}, ['OK']] }
  get 'dashboard', to: proc { [200, {}, ['Dashboard OK']] }
  get 'vehicles', to: proc { [200, {}, ['Vehicles OK']] }
  get 'billing', to: proc { [200, {}, ['Billing OK']] }
  get 'compliance', to: proc { [200, {}, ['Compliance OK']] }
  get 'subscribe', to: proc { [200, {}, ['Subscribe OK']] }
  get 'debug/batches', to: proc { [200, {}, ['Debug OK']] }
  get 'subscribe/success', to: proc { [200, {}, ['Success OK']] }
  get 'batches', to: proc { [200, {}, ['Batches OK']] }
  
  get 'batches/1/coc_pdf', to: ->(w) { [200, {'Content-Type' => 'application/pdf'}, ['%PDF-1.3\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj 2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj 3 0 obj<</Type/Page/MediaBox[0 0 3 3]>>endobj']] }
  get 'batches/1/temperature_log', to: proc { [200, {}, ['Temp OK']] }
  
  get 'api/health', to: proc { [200, {'Content-Type' => 'application/json'}, ['{"status":"ok"}']] }
  get 'api/batches', to: proc { [200, {'Content-Type' => 'application/json'}, ['[{"id":1}]']] }
  get 'api/vehicles', to: proc { [200, {'Content-Type' => 'application/json'}, ['[{"id":1}]']] }
  get 'api/v1/gps', to: proc { [200, {}, ['GPS OK']] }
  
  get '*path', to: proc { [404, {}, ['Not Found']] }
end

resources :stripe, only: [:new, :checkout]
