Rails.application.routes.draw do
  # Your existing routes...
  
  get '/health', to: 'healthchecks#show'
  get '/404', to: 'errors#error404', as: :error_404
  get '/500', to: 'errors#error500', as: :error_500
  
  # Driver/Pharmacist portals
  get '/drivers/sign_in', to: 'devise/sessions#new'  # adjust as needed
  get '/pharmacists/sign_in', to: 'devise/sessions#new'
  get '/up', to: -> { {status: 'ok'}.to_json }
end

root 'dashboard#index'
get 'dashboard', to: 'dashboard#index', as: :dashboard
resources :gps, only: [:index, :create] do
  collection { get :stream }
end
get 'test_pdf', to: 'pdfs#test'
