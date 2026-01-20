Rails.application.routes.draw do
  root "batches#index"
  resources :batches
devise_for :users :users :users if defined?(User.try(:devise))
end
