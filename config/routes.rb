Rails.application.routes.draw do
  # Phase 23: Revenue Test (SAFEST possible)
  get "/revenue-test", to: "homepage#revenue_test"
  
  # Keep your existing dashboard
  root "homepage#index"
end
