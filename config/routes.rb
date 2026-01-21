Rails.application.routes.draw do
  # Phase 22: TEXT endpoint first (no PDF complexity)
  get '/test-revenue', to: 'homepage#test_revenue'
  root "homepage#index"
end
