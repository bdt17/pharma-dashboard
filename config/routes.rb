Rails.application.routes.draw do
  root "batches#index"
  resources :batches, except: [:index]
end
