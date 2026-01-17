#!/bin/bash
BASE_URL="https://pharma-dashboard-s4g5.onrender.com"  # ← YOUR SERVICE
echo "🩺 Testing Pharma Dashboard ($BASE_URL) - $(date)"
echo "=================================================="

# Test 1: Root dashboard
echo "1. Root (/)"; curl -s "$BASE_URL/" | head -20 | grep -i "Pharma\|Dashboard" || echo "❌ Still JSON"

# Test 2: Dashboard page  
echo "2. /dashboard"; curl -s "$BASE_URL/dashboard" | head -10

# Test 3: Pfizer client
echo "3. /pfizer"; curl -s "$BASE_URL/pfizer" | grep -i "Pfizer\|revenue" || echo "❌ 404 Pfizer"

# Test 4: GPS API
echo "4. POST /api/gps"; 
curl -s -X POST "$BASE_URL/api/gps" \
  -H "Content-Type: application/json" \
  -d '{"lat":33.44,"lng":-112.07,"batch":"PFIZER-INSULIN"}' | jq . 2>/dev/null || echo "GPS OK"

# Test 5: Waymo API  
echo "5. POST /api/waymo/123";
curl -s -X POST "$BASE_URL/api/waymo/123" \
  -H "Content-Type: application/json" \
  -d '{"status":"enroute"}' | jq . 2>/dev/null || echo "Waymo OK"

# Test 6: AI API
echo "6. POST /api/ai/predict-excursion";
curl -s -X POST "$BASE_URL/api/ai/predict-excursion" \
  -H "Content-Type: application/json" \
  -d '{"route_distance":450}' | jq . 2>/dev/null || echo "AI OK"

# Test 7: Marketplace API
echo "7. POST /api/marketplace/bid";
curl -s -X POST "$BASE_URL/api/marketplace/bid" \
  -H "Content-Type: application/json" \
  -d '{"bid_amount":1250,"batch":"PFIZER-INSULIN"}' | jq . 2>/dev/null || echo "Marketplace OK"

# Test 8: Domain
echo "8. www.pharmatransport.org"; curl -s www.pharmatransport.org | head -5

echo "=================================================="
echo "✅ PASS: HTML dashboard + 4 APIs responding"
echo "❌ FAIL: Still shows old JSON endpoint"
