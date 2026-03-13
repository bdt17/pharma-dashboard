Rails.application.routes.draw do
  root 'home#index'
  get '/health', to: 'health#index'
  
  # Legacy routes for health script
  get '/dashboard', to: 'home#index'
  get '/batches', to: 'batches#index', as: :batches
  get '/subscribe', to: 'subscribe#index', as: :subscribe
  
  scope :enterprise, as: :enterprise do
    get '/dashboard', to: 'home#index', as: :dashboard
    get '/vehicles', to: 'home#vehicles', as: :vehicles
    get '/batches', to: 'batches#index', as: :batches
    get '/gps', to: 'home#gps', as: :gps
    get '/subscribe', to: 'subscribe#index', as: :subscribe
    get '/billing', to: 'subscribe#billing', as: :billing
  end
end
