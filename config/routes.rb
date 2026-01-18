Rails.application.routes.draw { root "dashboard#index" }
  get 'batches/:id/chain_of_custody', to: 'batches#chain_of_custody', as: :batch_chain_of_custody
