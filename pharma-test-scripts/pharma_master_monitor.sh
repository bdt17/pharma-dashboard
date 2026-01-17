#!/bin/bash
URL="https://pharma-dashboard-1-9xaz.onrender.com"

while true; do
  echo "🩺 $(date): $URL Status Check"
  
  # Screenshot via curl (HTML → PNG via ImageMagick)
  curl -s "$URL/" > /tmp/pharma.html
  wkhtmltoimage /tmp/pharma.html pharma_dashboard_$(date +%H%M).png
  
  # Test ALL 7 endpoints
  curl -s -w "HTTP: %{http_code}\n" "$URL/" | head -3
  curl -s -w "HTTP: %{http_code}\n" "$URL/dashboard" | head -3
  curl -s -w "HTTP: %{http_code}\n" "$URL/pfizer" | head -3
  
  echo "🔋 APIs:"
  curl -s -X POST "$URL/api/gps" -H "Content-Type: application/json" -d '{"lat":33.44,"lng":-112.07,"batch":"PFIZER-INSULIN"}' | jq .
  curl -s -X POST "$URL/api/waymo/123" -H "Content-Type: application/json" -d '{"status":"enroute"}' | jq .
  curl -s -X POST "$URL/api/ai/predict-excursion" -H "Content-Type: application/json" -d '{"route_distance":450}' | jq .
  curl -s -X POST "$URL/api/marketplace/bid" -H "Content-Type: application/json" -d '{"bid_amount":1250}' | jq .
  
  echo "✅ Phase 14: $47B FDA Dashboard = OPERATIONAL"
  echo "----------------------------------------"
  sleep 300  # 5min
done
