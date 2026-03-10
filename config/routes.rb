Rails.application.routes.draw do
  # Healthcheck endpoints
  get "up", to: "rails/health#show", as: :up
  get "health", to: "health#index", as: :health

  # Authentication (Devise)
  devise_for :users

  # Stripe endpoints
  get 'subscribe', to: 'stripe#new', as: :subscribe
  post '/stripe/checkout', to: 'stripe#checkout', as: :stripe_checkout
  get '/subscribe/success', to: 'stripe#success', as: :stripe_success
  post '/stripe/webhook', to: 'stripe#webhook', as: :stripe_webhook

  # Dashboard & Pages
  root 'batches#index'
  get 'dashboard', to: 'dashboard#index', as: :dashboard
  get 'vehicles', to: 'vehicles#index', as: :vehicles
  get 'billing', to: 'billing#index', as: :billing
  get 'compliance', to: 'compliance#index', as: :compliance

  # GPS IoT API (Queclink GV55)
  namespace :api do
    namespace :v1 do
      resources :gps, only: [:index, :show, :update]
    end
  end

  # API Namespace (JSON only)  
  namespace :api, defaults: { format: :json } do
    get :health, to: ->(w) { [200, {'Content-Type' => 'application/json'}, [{status: 'ok', uptime: 99.9, timestamp: Time.now.utc.iso8601}.to_json]] }
    resources :batches, only: [:index]
    resources :vehicles, only: [:index]
    resources :custody_logs, only: [:index, :show]
  end

  # Core resources - Chain of Custody PDFs
  resources :batches do
    member do
      get :custody_report, path: 'chain-of-custody'
      get :coc_pdf, defaults: { format: :pdf }
      get :temperature_log
    end
    collection do
      get :compliance_status
    end
  end

  resources :vehicles
  resources :custody_logs

  # Debug routes
  get 'debug/batches', to: 'batches#index', as: :debug_batches

  # Catch-all 404
  get '*path', to: 'application#not_found', constraints: ->(req) { !req.xhr? && req.format.html? }
end
get 'subscribe', to: 'stripe#new'
post '/stripe/checkout', to: 'stripe#checkout'
