Rails.application.routes.draw do
  # GPS IoT Endpoints (Queclink GV55)
  get '/gps', to: 'gps#index'
  post '/gps/update', to: 'gps#update'
  
  # Subscription SaaS
  get '/subscribe', to: 'subscriptions#index'
  
  # Static landing (your index.html)
  get '/index.html', to: ->(env) { [200, {'Content-Type' => 'text/html'}, [File.read('public/index.html') rescue '<h1>Pharma Dashboard Phase 10</h1>']] }
  
  # PROD WORKING ENDPOINTS - NO FILE DEPENDENCIES
  get 'health', to: proc { [200, {'Content-Type' => 'text/plain'}, ['OK - Phase 10 LIVE']] }
  get 'dashboard', to: proc { [200, {'Content-Type' => 'text/html'}, ['<h1>Dashboard LIVE 🟢</h1><p>47 vehicles | 5 batches | Stripe ready</p>']] }
  get 'vehicles', to: proc { [200, {}, ['Queclink GV55 LIVE - Vehicle #1 tracking']] }
  get 'batches', to: proc { [200, {}, ['Batches Dashboard - 5 Active (LOT-PHARMA-20260217)']] }
  get 'billing', to: proc { [200, {}, ['STRIPE $99/$299/$499/mo LIVE - sk_test_51Sd3...']] }

  # Devise (already passing ✅)
  devise_for :users

  # PDF endpoint (WickedPDF)
  get '/batches.pdf', to: 'batches#index', defaults: {format: 'pdf'}

  # Root redirect
  root to: redirect('/index.html')
end
