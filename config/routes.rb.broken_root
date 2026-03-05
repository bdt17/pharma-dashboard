Rails.application.routes.draw do
root 'batches#index'
  devise_for :users
  
  resources :batches do
  namespace :api do
    get "health", to: "api/health#index"
  end
    member do
      get 'chain-of-custody', to: 'batches#custody_report'
    end
  end
  
  root to: 'batches#index'
end
  get 'test-pdf', to: 'batches#custody_report', defaults: { id: 1 }
  post 'gps/update', to: 'gps#update'
  get 'dashboard', to: 'dashboard#index'
