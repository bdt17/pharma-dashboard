Rails.application.routes.draw do
  # === DEVise AUTH (clean /login → /logout) ===
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    sign_up: 'signup',
    password: 'reset-password'
  }

  # === PUBLIC HEALTH/MONITORING (no auth required) ===
  root 'dashboard#index'
  get '/public-dashboard', to: 'dashboard#public_index'
  get '/health', to: 'dashboard#health'
  get '/status', to: 'dashboard#status'
  
  # === PUBLIC DASHBOARD ENDPOINTS (Phase 1) ===
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'

  # === AUTHENTICATED PHARMA OPERATIONS (require login) ===
  authenticate :user do
    get '/trucks', to: 'dashboard#trucks'
    get '/shipments', to: 'dashboard#shipments'
    get '/routes', to: 'dashboard#routes'
    get '/dispatch', to: 'dashboard#dispatch'
    get '/alerts', to: 'dashboard#alerts'
  end

  # === GPS TRACKING API (Phase 2 ready) ===
  namespace :api do
    namespace :v1 do
      post   'gps/update', to: 'gps#update'
      get    'gps/stream', to: 'gps#stream'
      get    'gps/:id', to: 'gps#show'
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
  end

  # === DRIVER PORTAL (Phase 3B mobile-ready) ===
  namespace :driver do
    get    '/', to: 'dashboard#index'
    get    '/route/:id', to: 'routes#show'
    post   '/checkin/:batch_id', to: 'batches#checkin'
  end
end
