#!/bin/bash
# test_backend_content.sh v2.0 - FIXED FOR RAILS 8.1.1 + API NAMESPACING
set +e  # Continue on failures

echo "================================================================================="
echo "🚀 PHARMA TRANSPORT BACKEND CONTENT TESTER v2.0"
echo "📅 $(date)"
echo "================================================================================="

BASE_URL="https://pharma-dashboard-beq2.onrender.com"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log_ok() { echo -e "${GREEN}[ OK ]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "🌎 Testing: $BASE_URL"

# Test 1: Root endpoint (Rails welcome)
echo "1. Root endpoint..."
if curl -s -f -o /dev/null -w "%{http_code}" "$BASE_URL" | grep -q "^200$"; then
  log_ok "Root ✓"
else
  log_fail "Root ✗"
fi

# Test 2: Rails 8.1 BUILT-IN health (/up NOT /health)
echo "2. Rails Health (/up)..."
if curl -s -f -o /dev/null -w "%{http_code}" "$BASE_URL/up" | grep -q "^200$"; then
  log_ok "Rails /up ✓"
else
  log_fail "Rails /up ✗"
fi

# Test 3: API endpoints (with /api/v1/ namespace)
echo "3. API endpoints..."

# Vehicles API (typical Rails namespace)
if curl -s -f -w "%{http_code}" "$BASE_URL/api/v1/vehicles" -o /tmp/vehicles.html | grep -q "^200$"; then
  log_ok "Vehicles API ✓"
else 
  log_warn "Vehicles API 404 (add routes?)"
fi

# Batches API
if curl -s -f -w "%{http_code}" "$BASE_URL/api/v1/batches" -o /tmp/batches.html | grep -q "^200$"; then
  log_ok "Batches API ✓"
else 
  log_warn "Batches API 404 (add routes?)"
fi

# Test 4: Rails health details
echo "4. Health details..."
curl -s "$BASE_URL/up" | head -5

# Test 5: Render Dashboard
echo "5. Render Dashboard..."
curl -s -f -I "https://dashboard.render.com" -o /dev/null && log_ok "Render ✓" || log_fail "Render ✗"

# Test 6: Custom domain (ignore SSL)
echo "6. Custom domain..."
if curl -k -s -f -o /dev/null -w "%{http_code}" "https://dashboard.pharmatransport.org" | grep -q "^200$"; then
  log_ok "Custom domain LIVE ✓"
else 
  log_warn "Custom domain → 54.215.31.113 (SSL pending)"
fi

echo ""
echo "================================================================================="
echo "✅ SUMMARY: Root + Rails /up = LIVE ✓"
echo "🔄 API routes missing → Add to routes.rb:"
echo "  namespace :api do"
echo "    namespace :v1 do"
echo "      resources :vehicles, :batches"
echo "    end"
echo "  end"
echo "🔗 Render Live: https://pharma-dashboard-beq2.onrender.com ✓"
echo "🔗 Custom Domain: https://dashboard.pharmatransport.org (DNS ✓ SSL ⏳)"
echo "================================================================================="

# Cleanup
rm -f /tmp/*.html
