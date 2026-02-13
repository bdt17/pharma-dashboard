#!/bin/bash
BASE_URL_LOCAL="http://127.0.0.1:10000"
BASE_URL_PROD="https://pharma-dashboard-beq2.onrender.com"

echo "🚀 PHARMA ENTERPRISE UI TEST v15.0.0"
echo "LOCAL: $BASE_URL_LOCAL | PROD: $BASE_URL_PROD"
echo "==============================================="

test_page() {
  local url="$1"
  local page_name="$2"
  local expected_content="$3"
  
  echo -n "  $page_name ... "
  
  # Test LOCAL
  if curl -s -m 5 "$BASE_URL_LOCAL/$url" | grep -qi "$expected_content"; then
    echo -n "🟢 "
  else
    echo -n "🔴 "
  fi
  
  # Test PROD  
  if curl -s -m 5 "$BASE_URL_PROD/$url" | grep -qi "$expected_content"; then
    echo "🟢"
  else
    echo "🔴"
  fi
}

echo "🔍 TESTING 8 DASHBOARD PAGES:"
test_page "" "HOME" "Pharma Transport Dashboard"
test_page "health" "HEALTH" "PHARMA ENTERPRISE"
test_page "vehicles" "VEHICLES" "Active Vehicles"
test_page "batches" "BATCHES" "Temperature Alerts" 
test_page "compliance" "COMPLIANCE" "FDA Compliance"
test_page "billing" "BILLING" "MRR"
test_page "users/sign_in" "LOGIN" "Sign in"
test_page "users/sign_up" "SIGNUP" "Sign up"

echo ""
echo "📊 UI CONTENT RESULTS: $(curl -s $BASE_URL_LOCAL | grep -c 'Pharma') LOCAL | $(curl -s $BASE_URL_PROD | grep -c 'Pharma') PROD"
