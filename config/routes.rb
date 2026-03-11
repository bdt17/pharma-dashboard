Rails.application.routes.draw do
  # Homepage - PERFECT landing page
  root "landing#index"

  # Render health checks
  get '/up', to: 'rails/health#show', as: :rails_health_check
  get '/health', to: 'health#index'
  get '/api/health', to: 'health#show'

  # Auth (Devise)
  devise_for :users

  # Revenue & Subscriptions
  get '/subscribe', to: 'subscriptions#index'
  get '/billing', to: 'billing#index'
  get '/subscribe/success', to: 'subscriptions#success'

  # Dashboard & Core features
  get '/dashboard', to: 'dashboard#index'
  resources :vehicles
  resources :batches do
    member do
      get :chain_of_custody
      get :coc_pdf
      get :temperature_log
    end
  end

  # GPS Queclink GV55 IoT
  get '/gps', to: 'gps#index'
  get '/gps/update', to: 'gps#update'
  post '/gps/update', to: 'gps#update'
  get '/gps/update/stream', to: 'gps#stream'

  # Debug & Testing
  get '/debug/batches', to: 'batches#debug'
  get '/test-pdf', to: 'batches#test_pdf'

  # Compliance
  get '/compliance', to: 'compliance#index'

  # API endpoints
  namespace :api do
    namespace :v1 do
      resources :gps, only: [:index]
      resources :batches, only: [:index]
      resources :vehicles, only: [:index]
    end
  end
end
