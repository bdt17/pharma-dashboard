Rails.application.routes.draw do
  get "test_scripts/index"
  root "dashboard#index"
  
  resources :batches do
    member do
      get :chain_of_custody, controller: 'pdf_reports'
    end
  end
  
  # Add your other existing routes here later
end
  resources :batches
  get '/test_scripts', to: 'test_scripts#index', as: :test_scripts
