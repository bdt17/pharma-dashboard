Rails.application.routes.draw do
  root "batches#index"
  resources :batches
# DISABLED: devise_for :users :users if defined?(User.try(:devise))
end
