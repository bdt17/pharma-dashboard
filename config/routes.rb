Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  get '/logout', to: 'dashboard#logout'
  
  # 8 ENDPOINTS FOR test_ui_content.sh
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  get '/login', to: 'dashboard#login'
  
  # PDF custody reports
  get '/batches/:id/custody_report', to: 'batches#custody_report'
end
