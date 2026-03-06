Rails.application.routes.draw do
  get "checkout/create"
  
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

  # Core resources - FIXED PDF ROUTING
  resources :batches do
    member do
      # Chain of Custody - HTML viewer + PDF download
      # URLs: 
      # /batches/1/chain-of-custody → HTML viewer  
      # /batches/1/chain-of-custody.pdf → Raw PDF download
      get :custody_report, path: 'chain-of-custody'
      
      # Dedicated WickedPDF endpoint (legacy)
      get :coc_pdf
      
      # Batches list PDF
      # URL: /batches.pdf → Full batches list PDF
      collection do
        get :batches_pdf, path: 'batches', defaults: { format: :pdf }
      end
    end
  end

  resources :custody_logs

  # Legacy test route (keep for now)
  get 'test-pdf', to: 'batches#custody_report', defaults: { id: 1 }

  # Debug routes (temporary - remove after Phase 8 complete)
  get 'debug/batches', to: 'batches#index'
  get 'debug/batch/:id', to: 'batches#show'
end
