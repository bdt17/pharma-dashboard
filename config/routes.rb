Rails.application.routes.draw do
  root "landing#index"
  get '/pharmacists', to: 'landing#pharmacists'
  get '/patients', to: 'landing#patients'
end
