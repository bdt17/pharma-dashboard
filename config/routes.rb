Rails.application.routes.draw do
  root "batches#index"
  resources :batches
  # TEMP DISABLED devise_for :users if defined?(User.try(:devise))
end
