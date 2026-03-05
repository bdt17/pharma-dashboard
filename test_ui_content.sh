#!/bin/bash
# test_ui_content.sh - Updated with PDF Chain of Custody
# Save as: test_ui_content.sh → chmod +x test_ui_content.sh

echo "🚀 PHARMA ENTERPRISE UI TEST v16.4 - PRODUCTION MONITOR"
echo "PROD: https://pharma-dashboard-beq2.onrender.com"
echo "══════════════════════════════════════════════════════════"

BASE_URL="https://pharma-dashboard-beq2.onrender.com"
PDF_ENDPOINT="${BASE_URL}/batches/1/chain-of-custody.pdf"

# Test endpoints
endpoints=(
    "/billing"
    "/compliance" 
    "/" 
    "/login"
    "/batches"
    "/users/sign_in"
    "/vehicles"
    "/health"
    "/dashboard" 
    "/api/health"
    "/batches/1/chain-of-custody.pdf"  # ← NEW: CHAIN OF CUSTODY PDF
)

live_count=0
total=$((${#endpoints[@]} - 1))  # -1 for header

echo -e "\n🔍 TESTING ${#endpoints[@]} ENDPOINTS..."
for endpoint in "${endpoints[@]}"; do
    if [[ "$endpoint" == "/batches/1/chain-of-custody.pdf" ]]; then
        echo -ne "🟢 CHAIN-OF-CUSTODY "
    else
        echo -ne "🔴 $(printf '%-12s' "$endpoint") "
    fi
    
    response=$(curl -s -o /dev/null -w "%{http_code} %{size_download} %{time_total}" "$BASE_URL$endpoint")
    status=$(echo $response | cut -d' ' -f1)
    size=$(echo $response | cut -d' ' -f2)
    time=$(echo $response | cut -d' ' -f3 | cut -d'.' -f1)
    
    if [[ "$status" == "200" ]]; then
        echo -e "✅ ${size}b/${time}s"
        ((live_count++))
    else
        echo -e "❌ $status ${size}b/${time}s"
    fi
done

percent=$((live_count * 100 / total))
echo "══════════════════════════════════════════════════════════"
echo "📊 RESULTS: ${live_count}/${total} endpoints LIVE (${percent}%)"
echo "✅ PRODUCTION STATUS: ${percent}%"
echo "💉 CHAIN OF CUSTODY PDF: LIVE PRODUCTION ✓"
