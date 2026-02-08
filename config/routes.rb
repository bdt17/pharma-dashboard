Rails.application.routes.draw do
  root "dashboard#index"
  
  get "/health", to: "health#index"
  get "/api/health", to: "health#index"
  
  post "/gps/update", to: "gps#update"
  get "/gps/stream", to: "gps#stream"
  
  resources :vehicles
  resources :batches do
    member do
      get :chain_of_custody
    end
  end
  
  # Stripe Billing (SIMPLE - no nested block)
  resources :billing, only: [:index, :create]
  get "/billing/success", to: "billing#success"
  get "/billing/cancel", to: "billing#cancel"
  post "/stripe/webhook", to: "billing#webhook"
  
  # Devise (if exists)
  devise_for :users
  
  # Existing routes stay
end
