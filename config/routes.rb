Rails.application.routes.draw { root "dashboard#index"; resources :vehicles, :batches, :alerts, :drivers, :revenue, only: [:index] }
