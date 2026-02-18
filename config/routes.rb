Rails.application.routes.draw do
  root 'home#index'
  
  get 'health', to: 'health#index'
  get 'billing', to: 'billing#index'

  # Dashboard resources  
  resources :vehicles, only: [:index]
  resources :batches, only: [:index, :show] do
    get :chain_of_custody, on: :member
  end
  resources :compliance, only: [:index]

  # Authentication
  devise_for :users
end
