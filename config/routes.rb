Rails.application.routes.draw do
  root "batches#index"
  resources :batches
  devise_for :users
end
