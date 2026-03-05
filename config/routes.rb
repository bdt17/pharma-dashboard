Rails.application.routes.draw do
  devise_for :users
  
  resources :batches do
    member do
      get 'chain-of-custody', to: 'batches#custody_report'
    end
  end
  
  root to: 'batches#index'
end
