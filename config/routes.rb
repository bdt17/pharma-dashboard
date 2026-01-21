Rails.application.routes.draw do
  get '/batches/:id/chain_of_custody', to: 'pdfs#chain_of_custody'
  root "homepage#index"
end
