Rails.application.routes.draw do
  # Phase 21: FDA Revenue PDFs
  get '/batches/:id/chain_of_custody', to: 'revenue#chain_of_custody'
  get '/batches/:id/label', to: 'revenue#shipping_label'
  get '/batches/:id/manifest', to: 'revenue#manifest'
  
  # Existing routes below
  root "homepage#index"
