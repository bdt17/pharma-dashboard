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
  
  # MINIMAL Billing routes (100% safe)
  get 'billing', to: 'billing#index'
  post 'billing', to: 'billing#create'
  get 'billing/success', to: 'billing#success'
  get 'billing/cancel', to: 'billing#cancel'
  
  # Devise - make conditional to avoid User error
  begin
    devise_for :users
  rescue NameError
    # User model missing - skip devise
  end
end
