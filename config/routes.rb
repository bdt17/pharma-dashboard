Rails.application.routes.draw do
  # Healthcheck endpoints (Rails 8.1 + custom)
  get "up", to: "rails/health#show", as: :up
  get "health", to: "health#index", as: :health

  # Authentication
  devise_for :users

  # Stripe endpoints
  post '/stripe/create_intent', to: 'stripe#create_intent', as: :create_stripe_intent
  post '/stripe/webhook_test', to: 'stripe#webhook_test', as: :stripe_webhook_test
  post '/stripe/checkout', to: 'stripe#checkout', as: :stripe_checkout
  get '/stripe/success', to: 'stripe#success', as: :stripe_success
  get '/stripe/cancel', to: 'stripe#cancel', as: :stripe_cancel
  post '/stripe/webhook', to: 'stripe#webhook', as: :stripe_webhook

  # Dashboard & Pages
  root 'batches#index'
  get 'dashboard', to: 'dashboard#index', as: :dashboard
  get 'vehicles', to: 'vehicles#index', as: :vehicles
  get 'billing', to: 'billing#index', as: :billing
  get 'compliance', to: 'compliance#index', as: :compliance
  get 'subscribe', to: 'stripe#new', as: :subscribe

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
    get :health, to: ->(w) { [200, { 'Content-Type' => 'application/json' }, [{ status: 'ok', uptime: 99.9, timestamp: Time.now.utc.iso8601 }.to_json]] }

    resources :batches, only: [:index, :show] do
      member do
        get :custody_report, path: 'chain-of-custody'
        get :coc_pdf, defaults: { format: :pdf }
      end
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
  get 'debug/batches', to: 'batches#index', as: :debug_batches
  get 'debug/vehicles', to: 'vehicles#index', as: :debug_vehicles
  get 'debug/users', to: 'users#index', as: :debug_users if Rails.env.development?

  # Catch-all for 404
  get '*path', to: 'application#not_found', constraints: ->(req) { !req.xhr? && req.format.html? }
end
