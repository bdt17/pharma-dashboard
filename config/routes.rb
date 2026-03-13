Rails.application.routes.draw do
  # Phase 10 Enterprise Routes
  get '/health', to: 'health#index'
  get '/batches', to: 'batches#index'
  get '/subscribe', to: 'subscribe#index'
  
  # Root
  root 'application#index'
  
  # Existing routes preserved
  resources :batches, only: [] do
    member do
      get :chain_of_custody
    end
  end
end
