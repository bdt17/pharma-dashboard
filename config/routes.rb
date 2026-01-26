Rails.application.routes.draw do
  get "gps/update"
  get "gps/stream"
  root 'dashboard#index'
end

# GPS Tracking API (Phase 2)
post '/api/gps', to: 'gps#update'
get  '/api/gps/stream', to: 'gps#stream'

# Health check (Phase 3 prep)
get '/api/health', to: ->(w) { [200, {'Content-Type' => 'application/json'}, [{status: 'ok', rails: '8.1.1'}.to_json]] }

  # Thomas IT GPS API - Phase 2
  post '/api/gps', to: 'gps#update'
  get '/api/gps/stream', to: 'gps#stream' 
  get '/api/health', to: 'gps#health'
