Rails.application.routes.draw do
  root "dashboard#index"
  
  resources :batches do
    member do
      get :chain_of_custody, controller: 'pdf_reports'
    end
  end
  
  # Add your other existing routes here later
end
