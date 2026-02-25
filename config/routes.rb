Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  get '/logout', to: 'dashboard#logout'
  
  # ALL 8 TEST_UI_CONTENT.SH ENDPOINTS
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  get '/login', to: 'dashboard#login'
  
  # PDF Chain of Custody
  resources :batches do
    member do
      get :custody_report, :custody_pdf
    end
  end
end
