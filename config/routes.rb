Rails.application.routes.draw do
  resources :batches do
    member do
      get 'chain-of-custody', to: 'batches#custody_report', format: false
    end
  end
end
