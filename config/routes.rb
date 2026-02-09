Rails.application.routes.draw do
  # 📱 MAIN PAGES (WORKING 5/5)
  root "dashboard#index"
  get "/health", to: "dashboard#health"
  get "/vehicles", to: "dashboard#vehicles" 
  get "/batches", to: "dashboard#batches"
  get "/batches/:id/chain_of_custody", to: "dashboard#chain_of_custody"
  get "/billing", to: "dashboard#billing"
  
  # 🆕 API ROUTES (test_production_smart.rb)
  get "/api/health", to: "api#health"
  get "/test-pdf", to: "api#test_pdf"
  get "/shipments", to: "api#shipments"
  get "/trucks", to: "api#trucks"
  get "/routes", to: "api#routes"
end
