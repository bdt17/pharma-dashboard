Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "/gps", to: "gps#update"
    end
  end
end
