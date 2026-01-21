Rails.application.routes.draw do
  # Phase 21: FDA Revenue PDFs via ApplicationController
  get '/batches/:id/chain_of_custody', to: 'application#chain_of_custody'
  root "homepage#index"
end
