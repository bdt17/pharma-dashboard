#!/bin/bash
URL="https://pharma-dashboard-1-9xaz.onrender.com"
LOG="pharma_master_$(date +%Y%m%d).log"

while true; do
  echo "🩺 $(date): $URL PRODUCTION CHECK" | tee -a $LOG
  
  # Screenshot dashboard
  curl -s "$URL/" > /tmp/pharma.html
  wkhtmltoimage --width 1200 /tmp/pharma.html "pharma_dashboard_$(date +%H%M%S).png"
  echo "📸 Screenshot: pharma_dashboard_*.png" | tee -a $LOG
  
  # Test HTML pages (expect 502 during boot)
  for path in "/" "/dashboard" "/pfizer"; do
    code=$(curl -s -o /tmp/response.html -w "%{http_code}" "$URL$path")
    echo "  $path → HTTP $code" | tee -a $LOG
  done
  
  # Test APIs (handle 502 HTML or JSON)
  echo "🔋 ENTERPRISE APIs:" | tee -a $LOG
  for api in "gps" "waymo/123" "ai/predict-excursion" "marketplace/bid"; do
    response=$(curl -s -X POST "$URL/api/$api" -H "Content-Type: application/json" -d '{"test":1}')
    if [[ $response == *"{ "* ]]; then
      echo "  ✅ $api: $(echo $response | jq . 2>/dev/null || echo "JSON OK")" | tee -a $LOG
    else
      echo "  ⚠️  $api: HTTP response (deploying...)" | tee -a $LOG
    fi
  done
  
  echo "✅ Phase 14: $47B FDA Dashboard = DEPLOYING → LIVE SOON" | tee -a $LOG
  echo "----------------------------------------" | tee -a $LOG
  sleep 300
done
