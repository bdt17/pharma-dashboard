# FDA Revenue Phase 21
get "/batches/:id/chain_of_custody", to: "revenue#chain_of_custody"
Rails.application.routes.draw do
  root "home#index"
end

get '/batches/:id/chain_of_custody', to: 'revenue#chain_of_custody'
get '/batches/:id/label', to: 'revenue#shipping_label'  
get '/batches/:id/manifest', to: 'revenue#manifest'

get "/batches/:id/chain_of_custody", to: "revenue#chain_of_custody", as: :batch_chain_of_custody
get "/batches/:id/label", to: "revenue#shipping_label", as: :batch_label
get "/batches/:id/manifest", to: "revenue#manifest", as: :batch_manifest

