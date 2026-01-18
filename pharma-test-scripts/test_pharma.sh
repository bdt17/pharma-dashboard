#!/bin/bash
# test_pharma.sh - COMPLETE Pharma Dashboard Production Test Suite
# Tests ALL endpoints + FDA compliance + revenue features

BASE_URL="https://pharma-dashboard-clean.onrender.com"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')

echo "🩺 COMPLETE Pharma Dashboard PRODUCTION TEST - $TIMESTAMP"
echo "=================================================="
echo "Target: $BASE_URL"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL=0
PASS=0
FAIL=0

test_endpoint() {
    local endpoint=$1 method=${2:-GET} data=${3:-} expected=${4:-200} desc=${5:-$endpoint}
    TOTAL=$((TOTAL + 1))
    echo -n "  ${TOTAL}. $desc ... "
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" --max-time 15 -X POST \
            -H "Content-Type: application/json" -H "Accept: application/json" \
            -d "$data" "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" --max-time 15 "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "$expected" ]; then
        echo -e "${GREEN}✅ PASS ($http_code)${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}❌ FAIL ($http_code): $body${NC}"
        FAIL=$((FAIL + 1))
    fi
}

test_pdf() {
    local endpoint=$1 desc=${2:-$endpoint}
    TOTAL=$((TOTAL + 1))
    echo -n "  ${TOTAL}. $desc ... "
    
    response=$(curl -s -w "\n%{http_code}\n%{content_type}\n%{size_download}" \
        --max-time 15 -o /tmp/test.pdf "$BASE_URL$endpoint")
    
    http_code=$(echo "$response" | head -n1)
    content_type=$(echo "$response" | head -n2 | tail -n1)
    size=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ] && [[ "$content_type" == "application/pdf"* ]]; then
        echo -e "${GREEN}✅ PDF ($size bytes)${NC}"
        PASS=$((PASS + 1))
        rm -f /tmp/test.pdf
    else
        echo -e "${RED}❌ FAIL ($http_code) Type: $content_type Size: $size${NC}"
        FAIL=$((FAIL + 1))
    fi
}

echo "📊 WEB PAGES:"
test_endpoint "/" "" "" "200" "Homepage"
test_endpoint "/dashboard" "" "" "200" "Main Dashboard" 
test_endpoint "/batches" "" "" "200" "Batches List"
test_endpoint "/pfizer" "" "" "200" "Pfizer Dashboard"
test_endpoint "/login" "" "" "200" "Login Page"

echo ""
echo "🔗 FDA COMPLIANCE PDFs (Revenue Critical):"
test_pdf "/batches/1/chain_of_custody" "Chain of Custody PDF"
test_pdf "/batches/1/label" "Shipping Label PDF" 
test_pdf "/batches/1/manifest" "Cargo Manifest PDF"

echo ""
echo "🚀 CORE APIs:"
test_endpoint "/api/gps" POST '{"lat":33.4484,"lng":-112.0740,"speed":65}' "200" "GPS Tracking"
test_endpoint "/api/waymo/123" POST '{"event":"arrived"}' "200" "Waymo Integration"
test_endpoint "/api/ai/predict-excursion" POST '{"speed":75,"route":"I-10"}' "200" "AI Prediction"
test_endpoint "/api/marketplace/bid" POST '{"batch_id":1,"bid":2500}' "200" "Marketplace Bid"

echo ""
echo "🔐 AUTH & SECURITY:"
test_endpoint "/api/auth/signin" POST '{"email":"test@pharma.com","password":"test123"}' "200" "Devise Login"
test_endpoint "/api/current_user" GET "" "200" "Current User (auth req)"

echo ""
echo "📈 ENTERPRISE FEATURES:"
test_endpoint "/api/batches" GET "" "200" "Batch List"
test_endpoint "/api/batches/1" GET "" "200" "Single Batch" 
test_endpoint "/api/batches/stats" GET "" "200" "Batch Analytics"
test_endpoint "/api/audits" GET "" "200" "FDA Audit Trail"
test_endpoint "/api/compliance/report" GET "" "200" "Compliance Report"

echo ""
echo "⚡ PERFORMANCE:"
test_endpoint "/up" "" "" "200" "Health Check (Render)"
test_endpoint "/rails/info/properties" "" "" "200" "Rails Info"

echo ""
echo "=================================================="
echo "✅ RESULTS: $PASS/$TOTAL passed  ❌ $FAIL failed"
if [ $PASS -eq $TOTAL ]; then
    echo "💰 REVENUE STATUS: 🟢 FDA PRODUCTION LIVE!"
else
    echo "💰 REVENUE STATUS: 🔴 FIX REQUIRED"
fi
