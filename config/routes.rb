Rails.application.routes.draw do
  devise_for :patients
  devise_for :pharmacists
  root "landing#index"
  get "/gps", to: "gps#dashboard"
  get '/pharmacists/sign_in', to: 'pharmacists#new'
  get '/patients/sign_in', to: 'patients#new'
end
