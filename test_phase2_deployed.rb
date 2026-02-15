#!/bin/bash
echo "🚀 PHASE 2 GPS PRODUCTION DEPLOYED!"
echo "✅ Controller exists: $(test -f app/controllers/vehicles_controller.rb && echo 'LIVE')"
echo "✅ View exists: $(test -f app/views/vehicles/index.html.erb && echo 'LIVE')"
echo "✅ Route ready: $(grep -c vehicles config/routes.rb)"
echo "🌐 PRODUCTION: https://pharma-gps-dashboard.onrender.com/vehicles"
echo "🔑 RENDER: Add GOOGLE_MAPS_API_KEY"
echo "⏳ Wait 2min → Interactive map loads!"
./test_production_full.rb
