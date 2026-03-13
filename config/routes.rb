Rails.application.routes.draw do
  get '/health', to: 'health#index'
  get '/batches', to: 'batches#index'
  get '/subscribe', to: 'subscribe#index'
  get '/batches/:id/chain-of-custody', to: 'batches#chain_of_custody'
  root 'application#index'
end
