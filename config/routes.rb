Rails.application.routes.draw do
  root "dashboard#index"
  
  resources :batches do
    member do
      get :chain_of_custody, controller: 'pdf_reports'
    end
  end
  
  get '/test_scripts', to: 'test_scripts#index'
end
