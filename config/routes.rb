Rails.application.routes.draw do
  devise_for :users
  
  root 'dashboard#index'
  get '/dashboard', to: 'dashboard#index'
  
  # 8 PRODUCTION ENDPOINTS
  get '/health', to: 'dashboard#health'
  get '/vehicles', to: 'dashboard#vehicles'
  get '/batches', to: 'dashboard#batches'
  get '/billing', to: 'dashboard#billing'
  get '/compliance', to: 'dashboard#compliance'
  get '/login', to: 'dashboard#login'
  
  # Logout (simple GET)
  get '/logout', to: 'dashboard#logout'
  
  # PDF custody reports
  get '/batches/:id/custody_report', to: 'batches#custody_report'
end
