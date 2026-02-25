Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: 'users/sessions' }
  
  root 'dashboard#index'
  get '/dashboard' => 'dashboard#index', as: :dashboard
  
  resources :batches do
    member do
      get :custody_report
    end
  end
  
  # Public API endpoints (keep unprotected)
  get '/dashboard/vehicles', to: 'dashboard#vehicles'
  get '/dashboard/batches', to: 'dashboard#batches'
  get '/dashboard/billing', to: 'dashboard#billing'
  get '/dashboard/compliance', to: 'dashboard#compliance'
  get '/dashboard/health', to: 'dashboard#health'
end
