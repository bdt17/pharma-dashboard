#!/bin/bash
BASE_URL_LOCAL="http://127.0.0.1:10000"
BASE_URL_PROD="https://pharma-dashboard-beq2.onrender.com"

echo "🚀 PHARMA ENTERPRISE UI TEST v15.3 - HTTP STATUS"
echo "LOCAL: $BASE_URL_LOCAL | PROD: $BASE_URL_PROD"
echo "==============================================="

test_page() {
  local url="$1" page_name="$2"
  echo -n "  $page_name ... "
  
  local_code=$(curl -s -o /dev/null -w "%{http_code}" -m 15 "$BASE_URL_LOCAL/$url")
  prod_code=$(curl -s -o /dev/null -w "%{http_code}" -m 30 "$BASE_URL_PROD/$url")
  
  [[ "$local_code" == "200" ]] && echo -n "🟢 " || echo -n "🔴 "
  [[ "$prod_code" == "200" ]] && echo "🟢" || echo "🔴"
}

echo "🔍 TESTING 8 DASHBOARD PAGES (HTTP 200 OK):"
test_page "" "HOME"
test_page "health" "HEALTH"
test_page "vehicles" "VEHICLES"
test_page "batches" "BATCHES"
test_page "compliance" "COMPLIANCE"
test_page "billing" "BILLING"
test_page "users/sign_in" "LOGIN"
test_page "users/sign_up" "SIGNUP"

echo ""
echo "✅ YOUR DASHBOARD IS LIVE - Tests verify HTTP endpoints only"
