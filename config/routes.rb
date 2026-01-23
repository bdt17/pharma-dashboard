Rails.application.routes.draw do
  # API v1 namespace (JSON only)
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post "/gps", to: "gps#update"
      get  "/vehicles/:id", to: "vehicles#show"
    end
  end

  # Working APIs (keep these)
  get '/api/health', to: 'health#show'
  get '/batches', to: 'batches#index'
  
  # FDA Chain of Custody
  get '/reports/chain-of-custody/:id', to: 'reports#chain_of_custody', as: :chain_of_custody
  
  # Root dashboard
  root 'dashboard#index'
end
