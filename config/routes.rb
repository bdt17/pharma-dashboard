Rails.application.routes.draw do
  # API v1 (JSON only)
  namespace :api do
    namespace :v1 do
      post "/gps", to: "gps#update"
      get  "/vehicles/:id", to: "vehicles#show"
    end
  end

  # Existing working routes
  get '/api/health', to: 'health#show'
  get '/batches', to: 'batches#index'
  get '/reports/chain-of-custody/:id', to: 'reports#chain_of_custody', as: :chain_of_custody
  root 'dashboard#index'
end
