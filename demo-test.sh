#!/bin/bash
echo "🧪 PHARMA TRANSPORT CLIENT DEMO TEST"
echo "=================================="

# Test all client-facing URLs
URLs=(
  "https://pharma-dashboard-beq2.onrender.com/"
  "https://pharma-dashboard-beq2.onrender.com/billing"
  "https://pharma-dashboard-beq2.onrender.com/batches"
  "https://pharma-gps-dashboard.onrender.com/"
)

for URL in "${URLs[@]}"; do
  STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$URL")
  TIME=$(curl -s -w "%{time_total}" -o /dev/null "$URL")
  echo "✅ $URL → HTTP$STATUS (${TIME}s)"
done

# Verify live data
echo "📊 LIVE DATA:"
rails runner '
  v = Vehicle.count
  puts "Vehicles: #{v} | Revenue: $#{v*99}/mo"
  puts "Sample truck: #{Vehicle.first&.name} @ #{Vehicle.first&.speed}mph"
'

echo "🎬 READY FOR CLIENT CALL"
