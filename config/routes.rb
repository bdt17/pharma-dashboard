# config/routes.rb
Rails.application.routes.draw do
  resources :batches    # Line 13 should be here
  resources :vehicles
  resources :compliance
  # ... other resources
  root 'home#index'     # or whatever your home page is
  get 'health', to: 'health#index'
  devise_for :users
end
