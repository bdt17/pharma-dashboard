Rails.application.routes.draw do
  # Authentication
  devise_for :users

  # Dashboard & Pages
  root 'batches#index'
  get 'dashboard', to: 'dashboard#index'
  get 'vehicles', to: 'vehicles#index'
  get 'health', to: 'health#index'
  get 'billing', to: 'billing#index'
  get 'compliance', to: 'compliance#index'

  # API
  get 'api/health', to: 'api/health#index'

  # GPS IoT
  post 'gps/update', to: 'gps#update'
  get 'gps/update/stream', to: 'gps#stream'

  # Core resources
  resources :batches do
    member do
      # Chain of Custody - supports both HTML and PDF formats
      # URLs: /batches/1/chain-of-custody & /batches/1/chain-of-custody.pdf
      get :custody_report, path: 'chain-of-custody', as: :chain_of_custody
      
      # Dedicated WickedPDF endpoint
      # URL: /batches/1/coc_pdf
      get :coc_pdf
    end
  end

  resources :custody_logs

  # Legacy test route (keep for now)
  get 'test-pdf', to: 'batches#custody_report', defaults: { id: 1 }

  # Debug routes (temporary - remove after Phase 8 complete)
  get 'debug/batches', to: 'batches#index'
  get 'debug/batch/:id', to: 'batches#show'
end
