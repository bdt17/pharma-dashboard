#!/bin/bash
# Pharma Dashboard Complete Test Suite (Devise + Protected Routes)
# Fixed URL + Clickable Links + Full Auth Flow + PDF Tests

URL="https://pharma-dashboard-beq2.onrender.com"
ADMIN_EMAIL="admin@pharmagps.com"
ADMIN_PASS="password123"

echo "🚀 Testing: [Pharma Dashboard]($URL)"
echo "=================================="
rm -f cookies.txt

# 1. Login page loads (200) - CLICKABLE
echo "1. [Login Page](https://pharma-dashboard-beq2.onrender.com/users/sign_in)"
status=$(curl -s -o /dev/null -w "%{http_code}" "$URL/users/sign_in")
echo "   HTTP: $status $([[ $status == "200" ]] && echo "✅ Devise Ready" || echo "❌ 500 FIX ROUTES")"

# 2. POST Login (302 redirect + session)
echo "2. [Login POST](https://pharma-dashboard-beq2.onrender.com/users/sign_in)"
LOGIN_RESPONSE=$(curl -s -c cookies.txt -b cookies.txt \
  -X POST "$URL/users/sign_in" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "user[email]=$ADMIN_EMAIL&user[password]=$ADMIN_PASS" \
  -w "HTTP: %{http_code}")

echo "   $LOGIN_RESPONSE"
[[ ! -s cookies.txt ]] && echo "   ❌ NO COOKIES - Auth FAILED" && exit 1

# 3. Dashboard (auth required 200)
echo "3. [Dashboard Protected](https://pharma-dashboard-beq2.onrender.com/dashboard)"
DASHBOARD=$(curl -s -b cookies.txt "$URL/dashboard" -w "HTTP: %{http_code}")
echo "   $DASHBOARD"
echo "   $(echo "$DASHBOARD" | grep -i "vehicles\\|batches" || echo "❌ No dashboard content")"

# 4. Custody Report PDF (auth required)
echo "4. [Custody PDF](https://pharma-dashboard-beq2.onrender.com/batches/1/custody_report)"
PDF_STATUS=$(curl -s -b cookies.txt -o custody_report.txt \
  -w "HTTP: %{http_code}" "$URL/batches/1/custody_report")
echo "   $PDF_STATUS"
cat custody_report.txt

# 5. Public APIs (no auth needed)
echo "5. [Health Check](https://pharma-dashboard-beq2.onrender.com/dashboard/health)"
curl -s "$URL/dashboard/health"

echo "6. [Vehicles API](https://pharma-dashboard-beq2.onrender.com/dashboard/vehicles)"
curl -s "$URL/dashboard/vehicles"

# FINAL STATUS
echo ""
echo "✅ TEST SUMMARY:"
echo "   Cookies: $([ -s cookies.txt ] && echo "✅ SAVED" || echo "❌ MISSING")"
echo "   Dashboard: $(echo "$DASHBOARD" | grep -o "HTTP: [0-9]*" | tail -1)"
echo "   PDF Report: $PDF_STATUS"
echo "🔗 [OPEN DASHBOARD](https://pharma-dashboard-beq2.onrender.com/dashboard)"
echo "🍪 Cookies saved: cookies.txt ($(du -h cookies.txt 2>/dev/null || echo 'empty'))"
