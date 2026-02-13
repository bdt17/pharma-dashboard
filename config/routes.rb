Rails.application.routes.draw do
  # 🔐 DEVISE AUTHENTICATION FIRST (enterprise security)
  devise_for :users
  devise_scope :user do
    get 'login', to: 'users/sessions#new', as: :new_user_session
    get 'register', to: 'users/registrations#new', as: :new_user_registration
  end

  # 🌐 PUBLIC ENDPOINTS (no login required)
  get 'health', to: 'home#health'

  # 🔒 PROTECTED DASHBOARDS (login required via application_controller.rb)
  root "home#index"                    # / → Pharma dashboard (47 vehicles)
  get 'dashboard', to: 'home#dashboard' # /dashboard → same dashboard
  get 'vehicles', to: 'vehicles#index'  # /vehicles → GPS tracking
  get 'batches', to: 'batches#index'    # /batches → Temperature alerts  
  get 'compliance', to: 'compliance#index' # /compliance → FDA 21 CFR Part 11
  get 'billing', to: 'billing#index'    # /billing → $4,653 MRR Stripe

  # 🚀 GPS API (future Phase 2)
  post '/gps/update', to: 'home#gps_update'
end
