#!/bin/bash
echo "🚀 FORCE DEPLOY LANDING PAGE + CACHE BUST"

# Backup + deploy config.ru
cp config.ru config.ru.landing.$(date +%s)
git add config.ru
git commit -m "force: landing page v1 z9999 login button"
git push origin main

# Wait + test endpoints
sleep 180
echo "=== PRODUCTION TESTS ==="
/usr/local/bin/pharma-test
./test_production_pdf_v4_fixed.rb

# Test landing specifically
curl -s https://pharma-dashboard-beq2.onrender.com/ | grep -i "Enterprise Login" && echo "✅ LOGIN BUTTON LIVE" || echo "❌ LOGIN BUTTON MISSING"
