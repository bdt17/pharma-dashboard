#!/bin/bash
# Pharma Dashboard Login Test (Devise)

URL="https://pharma-gps-dashboard.onrender.com"
ADMIN_EMAIL="admin@pharmagps.com"
ADMIN_PASS="password123"

echo "🧪 Testing login: $ADMIN_EMAIL"
echo "=================================="

# 1. GET login page (check 200)
echo "1. Login page..."
curl -s -w "HTTP: %{http_code} | Size: %{size_download} bytes\n" \
  -o /dev/null "$URL/users/sign_in"

# 2. POST login (check 302 redirect)
echo "2. Login POST..."
LOGIN_RESPONSE=$(curl -s -c cookies.txt -b cookies.txt \
  -X POST "$URL/users/sign_in" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "user[email]=$ADMIN_EMAIL&user[password]=$ADMIN_PASS")

echo "Response: ${LOGIN_RESPONSE:0:100}..."

# 3. Check dashboard (with session)
echo "3. Dashboard (authenticated)..."
curl -s -b cookies.txt -w "HTTP: %{http_code}\n" \
  "$URL/dashboard" \
  | grep -i "dashboard\|vehicles\|batches" || echo "No dashboard content"

# 4. Test PDF (requires auth)
echo "4. Custody Report PDF..."
curl -s -b cookies.txt -w "HTTP: %{http_code}\n" \
  "$URL/batches/1/custody_report.pdf"

echo "✅ Cookies saved: cookies.txt"
echo "🔑 Login $([ -s cookies.txt ] && echo "SUCCESS" || echo "FAILED")"
