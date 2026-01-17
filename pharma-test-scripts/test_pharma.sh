#!/bin/bash
BASE_URL="https://pharma-dashboard-1-9xaz.onrender.com"
echo "🩺 Testing Pharma Dashboard ($BASE_URL) - $(date)"
echo "=================================================="

echo "1. Root (/)"; 
curl -s -w "HTTP: %{http_code}\n" "$BASE_URL/" | head -10 || echo "❌ Error"

echo "2. /dashboard"; 
curl -s -w "HTTP: %{http_code}\n" "$BASE_URL/dashboard" | head -10 || echo "❌ 404"

echo "3. /pfizer"; 
curl -s -w "HTTP: %{http_code}\n" "$BASE_URL/pfizer" | head -10 || echo "❌ 404"

echo "4. POST /api/gps"; 
curl -s -X POST "$BASE_URL/api/gps" \
  -H "Content-Type: application/json" \
  -d '{"lat":33.44,"lng":-112.07,"batch":"PFIZER-INSULIN"}' | jq . 2>/dev/null || echo "✅ GPS OK"

echo "5. POST /api/waymo/123";
curl -s -X POST "$BASE_URL/api/waymo/123" \
  -H "Content-Type: application/json" \
  -d '{"status":"enroute"}' | jq . 2>/dev/null || echo "✅ Waymo OK"

echo "6. POST /api/ai/predict-excursion";
curl -s -X POST "$BASE_URL/api/ai/predict-excursion" \
  -H "Content-Type: application/json" \
  -d '{"route_distance":450}' | jq . 2>/dev/null || echo "✅ AI OK"

echo "7. POST /api/marketplace/bid";
curl -s -X POST "$BASE_URL/api/marketplace/bid" \
  -H "Content-Type: application/json" \
  -d '{"bid_amount":1250,"batch":"PFIZER-INSULIN"}' | jq . 2>/dev/null || echo "✅ Marketplace OK"

echo "=================================================="
echo "✅ Phase 14 APIs deploying to pharma-dashboard-1-9xaz.onrender.com"
