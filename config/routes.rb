Rails.application.routes.draw do
  get "compliance/index"
  get "compliance/logs"
  get "compliance/signatures"
  get "drivers/index"
  get "drivers/show"
  get "drivers/sessions"
  get "revenue/index"
  get "alerts/index"
  get "alerts/show"
  get "batches/index"
  get "batches/show"
  get "batches/new"
  get "batches/edit"
  get "vehicles/index"
  get "vehicles/show"
  get "vehicles/new"
  get "vehicles/edit"
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
namespace :api do
  post '/gps', to: 'gps#create'
end
end



root "dashboard#index"
get "dashboard", to: "dashboard#index", as: :dashboard_index
resources :vehicles, only: [:index, :show]
resources :batches, only: [:index, :show] 
resources :alerts, only: [:index, :show]
resources :drivers, only: [:index, :show]
get "revenue", to: "revenue#index", as: :revenue
get "compliance", to: "compliance#index", as: :compliance
