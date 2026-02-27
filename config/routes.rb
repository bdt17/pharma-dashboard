Rails.application.routes.draw do
  # === DEVise AUTH (clean /login → /logout) ===
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    sign_up: 'signup',
    password: 'reset-password'
  }

  # === PUBLIC HEALTH/MONITORING (no auth - for uptime checks) ===
  get '/health', to: proc { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  get '/status', to: 'dashboard#status'
  get '/public-dashboard', to: 'dashboard#public_index'

  # === PUBLIC DASHBOARD ENDPOINTS (Phase 1 - no auth) ===
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'

  # === PROTECTED DASHBOARD ROOT (requires login) ===
  root 'dashboard#index'

  # === AUTHENTICATED PHARMA OPERATIONS (require login) ===
  authenticate :user do
    get '/trucks', to: 'dashboard#trucks'
    get '/shipments', to: 'dashboard#shipments'
    get '/routes', to: 'dashboard#routes'
    get '/dispatch', to: 'dashboard#dispatch'
    get '/alerts', to: 'dashboard#alerts'
  end

  # === GPS TRACKING API v1 (Phase 2 - public for IoT devices) ===
  namespace :api do
    namespace :v1 do
      # GPS endpoints (no auth - IoT devices)
      post   'gps/update', to: 'gps#update'
      get    'gps/stream', to: 'gps#stream'
      get    'gps/:id', to: 'gps#show'

      # Health + metrics (public)
      get    'health', to: 'health#show'
      get    'metrics', to: 'health#metrics'
    end
  end

  # === FDA COMPLIANCE REPORTS (Phase 3A) ===
  resources :batches, only: [:index, :show] do
    member do
      get  :custody_report, path: 'chain-of-custody'
      get  :temperature_log
      post :sign_electronic
    end
    collection do
      get :compliance_status
    end
  end

  # === DRIVER PORTAL (Phase 3B - mobile PWA) ===
  namespace :driver do
    get    '/', to: 'dashboard#index'
    get    '/route/:id', to: 'routes#show'
    post   '/checkin/:batch_id', to: 'batches#checkin'
  end

  # === ADMIN OPERATIONS (superadmin only) ===
  namespace :admin do
    resources :users
    resources :vehicles
    resources :organizations
    get '/reports', to: 'reports#index'
  end

  # === ENTERPRISE FEATURES (Phase 8-9) ===
  post '/create-checkout-session', to: 'stripe#create_checkout_session'
  get '/batches/:id/chain_of_custody.pdf', to: 'batches#chain_of_custody', as: :batch_chain_of_custody
end
