Rails.application.routes.draw do
  get "gps/update"
  get "gps/stream"
  root 'dashboard#index'
end
