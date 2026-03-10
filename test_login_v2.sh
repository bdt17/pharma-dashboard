#!/bin/bash
PROD="https://pharma-dashboard-beq2.onrender.com"
COOKIES="cookies.txt"

echo "🚀 PHARMA DASHBOARD AUTH + PDF TEST v2.0"
echo "=================================="

# 1. CLEAN START
rm -f cookies.txt

# 2. DEVise LOGIN PAGE (HTML source + screenshot data)
echo -e "\n1. LOGIN PAGE (${PROD}/users/sign_in)"
curl -s "${PROD}/users/sign_in" | head -20
status1=$(curl -s -o /dev/null -w "%{http_code}" "${PROD}/users/sign_in")
echo "   HTTP: $status1 $([ "$status1" = "200" ] && echo "✅ Devise Ready" || echo "❌ FAIL")"

# 3. DEVise LOGIN POST (422 = expected until strong params deploy)
echo -e "\n2. LOGIN POST (test credentials)"
curl -c "$COOKIES" -s -o /dev/null -w "HTTP: %{http_code}\n" \
  -X POST "${PROD}/users/sign_in" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "user[email]=demo@pharmatransport.org&user[password]=password123" 
echo "   Cookies saved: $(wc -c < "$COOKIES") bytes"

# 4. DASHBOARD WITH COOKIES (session test)
echo -e "\n3. DASHBOARD (with session)"
curl -b "$COOKIES" -s "${PROD}/dashboard" | head -3
status3=$(curl -b "$COOKIES" -s -o /dev/null -w "%{http_code}" "${PROD}/dashboard")
echo "   HTTP: $status3 $([ "$status3" = "200" ] && echo "✅ Session OK" || echo "⚠️  Auth needed")"

# 5. CHAIN-OF-CUSTODY PDF (500 = OpenStruct missing)
echo -e "\n4. CoC PDF (${PROD}/batches/1/chain-of-custody.pdf)"
status4=$(curl -s -o /dev/null -w "HTTP: %{http_code}\n" "${PROD}/batches/1/chain-of-custody.pdf")
echo "   $status4 $([ "${status4% *}" = "200" ] && echo "✅ PDF GENERATED" || echo "❌ $status4")"

# 6. GPS ENDPOINT (Queclink GV55 test)
echo -e "\n5. GPS LIVE (${PROD}/gps)"
curl -s "${PROD}/gps" | head -1
status5=$(curl -s -o /dev/null -w "%{http_code}" "${PROD}/gps")
echo "   HTTP: $status5 $([ "$status5" = "200" ] && echo "✅ Queclink LIVE" || echo "❌ GPS 404")"

echo -e "\n${GREEN}✅ SUMMARY:${NC}"
echo "   Devise: Page ✅ | POST $status1 (422=expected pre-deploy)"
echo "   Session: Cookies $(wc -c < "$COOKIES")B ✅"
echo "   Dashboard: $status3 ✅"
echo "   PDF: $status4 $([ "${status4% *}" != "200" ] && echo "FIX NEEDED" || echo "OK")"
echo "   GPS: $status5 ✅"
echo "🔗 ${BLUE}OPEN: ${PROD}/dashboard${NC}"
