Rails.application.routes.draw do
  get "/revenue-test", to: "homepage#revenue_test"
  get "/coc/:id", to: "application#chain_of_custody"  # FDA PDFs
  root "homepage#index"
end
