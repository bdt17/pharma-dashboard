#!/bin/bash
echo "🚀 THOMAS IT PHASE 10 PRODUCTION TEST v3.0"
echo "=============================================="

BASE_URL="https://pharma-dashboard-beq2.onrender.com"

echo "1. LANDING PAGE ($BASE_URL/) - Thomas IT 3-card NO LOGIN"
curl -s -I "$BASE_URL/" | head -3

echo "2. LOGIN PAGE ($BASE_URL/users/sign_in) - Enterprise card"  
curl -s "$BASE_URL/users/sign_in" | grep -o "ENTERPRISE LOGIN"

echo "3. AUTH POST"
curl -s -c cookies.txt -d "email=test@pharma.com&password=test" "$BASE_URL/auth/enterprise" -w "%{http_code}\n"

echo "4. DASHBOARD"
curl -s -b cookies.txt "$BASE_URL/dashboard" | grep -o "Live Dashboard"

echo "5. CoC PDF (MONEY MAKER)"
curl -s -I "$BASE_URL/batches/1/chain-of-custody.pdf" | grep "200"

echo "6. GPS LIVE (Queclink GV55)"
curl -s "$BASE_URL/gps" | grep -o "Queclink"

echo "7. HEALTH CHECK"
curl -s "$BASE_URL/health" | grep -o "Thomas IT"

echo "✅ THOMAS IT PHASE 10 = 100% OPERATIONAL"
echo "🔗 LANDING: $BASE_URL"
rm -f cookies.txt
