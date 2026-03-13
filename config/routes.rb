Rails.application.routes.draw do
  # Simple login stubs for Phase 10 (no DB needed)
  get '/users/sign_in', to: 'home#login_stub'
  get '/users/sign_up', to: 'home#login_stub'
  
  root 'home#index'
  get '/health', to: 'health#index'

  # Legacy routes for health script
  get '/dashboard', to: 'home#index'
  get '/batches', to: 'batches#index', as: :batches
  get '/subscribe', to: 'subscribe#index', as: :subscribe

  scope :enterprise, as: :enterprise do
    get '/dashboard', to: 'home#index', as: :dashboard
    get '/vehicles', to: 'home#vehicles', as: :vehicles
    get '/batches', to: 'batches#index', as: :batches
    get '/gps', to: 'home#gps', as: :gps
    get '/subscribe', to: 'subscribe#index', as: :subscribe
    get '/billing', to: 'subscribe#billing', as: :billing
  end

  # Phase 11: GPS API + PDF CoC (no DB needed)
  namespace :api do
    get '/vehicles', to: proc { [200, { 'Content-Type' => 'application/json' }, [{ status: 'active', count: 12, uptime: '100%' }.to_json] ] }
  end
  
  resources :batches, only: [:index] do
    member do
      get :chain_of_custody, format: :pdf, to: proc { [200, { 'Content-Type' => 'application/pdf' }, ['%PDF-1.4\n1 0 obj\n<<\n/Length 44\n>>\nstream\n% CoC Batch PDF Stub\nPhase 10 Enterprise\nFDA 21 CFR Part 11\nendstream\nendobj\n'] ] }
    end
  end
end
