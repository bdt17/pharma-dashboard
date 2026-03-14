#!/bin/bash
echo "🧪 PHASE 10 COMPLETE PRODUCTION TEST"
echo "===================================="

echo "1. Health check"
/usr/local/bin/pharma-test

echo "2. PDF generation"
./test_production_pdf_v4_fixed.rb

echo "3. Login flow"
./test_login_v3_production.sh

echo "4. Full endpoint suite" 
./test_production_full.rb

echo "5. Frontend content"
./testall_frontend_content_final.sh

echo "6. Landing page verification"
curl -s https://pharma-dashboard-beq2.onrender.com/ | grep -i "Enterprise Login" && echo "✅ Landing OK" || echo "❌ Landing broken"

echo "7. GPS endpoint"
curl -s -I https://pharma-dashboard-beq2.onrender.com/gps | head -1

echo "✅ ALL TESTS COMPLETE"
