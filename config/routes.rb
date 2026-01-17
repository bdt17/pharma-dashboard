Rails.application.routes.draw do
  post '/api/gps', to: -> (env) { 
    [200, {'Content-Type' => 'application/json'}, 
     [JSON.generate({status: 'received', batch: JSON.parse(env['rack.input'].read)['batch']})]] 
  }
  
  post '/api/waymo/:id', to: -> (env) { 
    [200, {'Content-Type' => 'application/json'}, 
     [JSON.generate({waymo_id: env['actioncontroller.params']['id'], status: 'enroute'})]] 
  }
  
  post '/api/ai/predict-excursion', to: -> (env) { 
    [200, {'Content-Type' => 'application/json'}, 
     [JSON.generate({risk: 0.12, status: 'safe'})]] 
  }
  
  post '/api/marketplace/bid', to: -> (env) { 
    [200, {'Content-Type' => 'application/json'}, 
     [JSON.generate({bid_accepted: true, amount: 1250})]] 
  }
  
  root "application#index"
end
namespace :api do
  post '/gps', to: 'gps#create'
end
