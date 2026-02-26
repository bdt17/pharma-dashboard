Rails.application.routes.draw do
  # === DEVise AUTH (clean /login → /logout) ===
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    sign_up: 'signup',
    password: 'reset-password'
  }

  # === PUBLIC HEALTH/MONITORING (no auth) ===
  root 'dashboard#index'
  get '/public-dashboard', to: 'dashboard#public_index'
  get '/health', to: 'dashboard#health'
  get '/status', to: 'dashboard#status'  # 👈 NEW: uptime + version
  
  # === PUBLIC DASHBOARD ENDPOINTS ===
  get '/vehicles', to: 'dashboard#vehicles', as: :public_vehicles
  get '/batches', to: 'dashboard#batches', as: :public_batches
  get '/billing', to: 'dashboard#billing', as: :public_billing
  get '/compliance', to: 'dashboard#compliance', as: :public_compliance

  # === AUTHENTICATED PHARMA OPERATIONS ===
  authenticate :user do
    get '/trucks', to: 'dashboard#trucks'
    get '/shipments', to: 'dashboard#shipments'
    get '/routes', to: 'dashboard#routes'
    get '/dispatch', to: 'dashboard#dispatch'  # 👈 NEW: Phase 5
    get '/alerts', to: 'dashboard#alerts'      # 👈 NEW: geofence/temp
  end

  # === GPS TRACKING API (Phase 2) ===
  namespace :api do
    namespace :v1 do
      # Real-time GPS updates
      post   'gps/update', to: 'gps#update'
      get    'gps/stream', to: 'gps#stream'
      get    'gps/:id', to: 'gps#show'
      
      # Health + metrics
      get    'health', to: 'health#show'
      get    'metrics', to: 'health#metrics'  # 👈 NEW: Prometheus
      
      # Compliance APIs (Phase 3)
      post   'batches/serialize', to: 'batches#serialize'
      get    'batches/:id/report', to: 'batches#custody_report'
    end
  end

  # === PHARMA COMPLIANCE (Phase 3A) ===
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

  # === DRIVER PORTAL (Phase 3B) ===
  namespace :driver do
    get    '/', to: 'dashboard#index'
    get    '/route/:id', to: 'routes#show'
    post   '/checkin/:batch_id', to: 'batches#checkin'
  end

  # === ADMIN OPERATIONS (Phase 5+) ===
  namespace :admin do
    resources :users
    resources :vehicles
    resources :organizations
    get '/reports', to: 'reports#index'
  end

  # === FDA 21 CFR Part 11 AUDIT LOGS ===
  get '/audit-logs', to: 'audit_logs#index', as: :audit_logs
end
