Rails.application.routes.draw do
  # Your existing routes...
  
  get '/health', to: 'healthchecks#show'
  get '/404', to: 'errors#error404', as: :error_404
  get '/500', to: 'errors#error500', as: :error_500
  
  # Driver/Pharmacist portals
  get '/drivers/sign_in', to: 'devise/sessions#new'  # adjust as needed
  get '/pharmacists/sign_in', to: 'devise/sessions#new'
end
get '/up', to: -> { {status: 'ok'}.to_json }
