Rails.application.routes.draw do
  # Existing health route (keep working)
  get '/health', to: 'healthchecks#show'
  
  # Pharma dashboard critical routes
  root 'dashboard#index'
  get 'dashboard', to: 'dashboard#index', as: :dashboard
  
  # GPS logistics endpoints
  resources :gps, only: [:index, :create] do
    collection { get :stream, path: 'update/stream' }
    member { get :update }
  end
  
  # PDF generation
  get 'test_pdf', to: 'pdfs#test', as: :test_pdf
  
  # API health
  get '/api/health', to: 'healthchecks#index'
end
