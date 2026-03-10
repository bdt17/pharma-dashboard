#!/bin/bash
echo "🚀 PHASE 10 FULL STACK HEALTH CHECK - PHARMA TRANSPORT"
echo "LOCAL: http://127.0.0.1:3000 | PROD: https://pharma-dashboard-beq2.onrender.com"
echo "═══════════════════════════════════════════════════════════════"

# Kill existing server
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# START RAILS SERVER IN BACKGROUND
echo "🟢 Starting Rails server on port 3000..."
bundle exec rails s -p 3000 -b 0.0.0.0 > server.log 2>&1 &
SERVER_PID=$!

sleep 5  # Wait for startup

# Test endpoints
ENDPOINTS=(
    "/" "Homepage"
    "/health" "Health" 
    "/dashboard" "Dashboard"
    "/vehicles" "Vehicles"
    "/batches" "Batches"
    "/subscribe" "Subscribe"
    "/billing" "Billing"
    "/compliance" "Compliance"
    "/api/health" "API Health"
    "/batches/1/chain-of-custody.pdf" "CoC PDF"
    "/users/sign_in" "Devise Login"
)

LOCAL_OK=0 PROD_OK=0 TOTAL=0
for endpoint in "${ENDPOINTS[@]}"; do
    ((TOTAL++))
    if [ $((TOTAL % 2)) -eq 1 ]; then
        URL=$endpoint
        continue
    fi
    NAME=$endpoint
    
    # Local test
    LOCAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000$URL || echo "FAIL")
    LOCAL_COLOR=$([ "$LOCAL_STATUS" = "200" ] && echo "🟢" || echo "🔴")
    
    # Prod test  
    PROD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://pharma-dashboard-beq2.onrender.com$URL || echo "FAIL")
    PROD_COLOR=$([ "$PROD_STATUS" = "200" ] && echo "🟢" || echo "🔴")
    
    [ "$LOCAL_STATUS" = "200" ] && ((LOCAL_OK++))
    [ "$PROD_STATUS" = "200" ] && ((PROD_OK++))
    
    printf "%-20s | %s | %s | %s\n" "$NAME" "$LOCAL_COLOR" "$PROD_COLOR" "$NAME"
done

echo "─────────────────────────────────────────────────────────"
echo "SUMMARY | ${LOCAL_OK}/${TOTAL} | ${PROD_OK}/${TOTAL} | $(bc -l <<< "${LOCAL_OK}*100/${TOTAL}%")% / $(bc -l <<< "${PROD_OK}*100/${TOTAL}%")%"
echo ""
echo "🟢 Server running (PID: $SERVER_PID)"
echo "📊 Logs: tail -f server.log"
echo "🛑 Stop: kill $SERVER_PID"
echo "🔄 Restart: ./test_pharma_full.sh"
