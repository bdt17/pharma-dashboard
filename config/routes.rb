Rails.application.routes.draw do
  # Healthcheck endpoints (Rails 8.1 + custom)
  get "up", to: "rails/health#show"
  get "health", to: "health#index"

  # Authentication
  devise_for :users

  # Stripe endpoints
  post '/stripe/create_intent', to: 'stripe#create_intent'
  post '/stripe/webhook_test', to: 'stripe#webhook_test'

  # Dashboard & Pages
  root 'batches#index'
  get 'dashboard', to: 'dashboard#index'
  get 'vehicles', to: 'vehicles#index'
  get 'billing', to: 'billing#index'
  get 'compliance', to: 'compliance#index'

  # GPS IoT API (Phase 10 - Queclink GV55)
  namespace :api do
    namespace :v1 do
      resources :gps, only: [:index, :show, :update] do
        collection do
          post :update
        end
      end
    end
  end

  # API Namespace (JSON only)  
  namespace :api, defaults: { format: :json } do
    get :health, to: ->(w) { { status: 'ok', uptime: 99.9, timestamp: Time.now.utc.iso8601 }.to_json }

    resources :batches, only: [:index, :show] do
      get :custody_report, path: 'chain-of-custody'
      get :coc_pdf, defaults: { format: :pdf }
    end

    resources :vehicles, only: [:index]
    resources :custody_logs, only: [:index, :show]
  end

  # Core resources - Chain of Custody PDFs
  resources :batches do
    member do
      get :custody_report, path: 'chain-of-custody'
      get :temperature_log
      post :sign_electronic
    end

    collection do
      get :compliance_status
      get :batches_pdf, path: 'batches', defaults: { format: :pdf }
    end
  end

  resources :vehicles
  resources :custody_logs

  # Debug routes (remove after Phase 10)
  get 'debug/batches', to: 'batches#index'
  get 'debug/batch/:id', to: 'batches#show'
end
