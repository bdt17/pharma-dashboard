#!/bin/bash
LOCAL_URL="http://127.0.0.1:10000"
PROD_URL="https://pharma-dashboard-beq2.onrender.com"
TIMEOUT=5

echo "🚀 PHARMA ENTERPRISE v16.3 - LOCAL vs PROD COMPARISON"
echo "LOCAL: $LOCAL_URL | PROD: $PROD_URL"
echo "══════════════════════════════════════════════════════════"

declare -A endpoints=(
    ["/"]="HOME"
    ["/health"]="HEALTH"
    ["/vehicles"]="VEHICLES" 
    ["/batches"]="BATCHES"
    ["/compliance"]="COMPLIANCE"
    ["/billing"]="BILLING"
    ["/login"]="LOGIN"
    ["/users/sign_in"]="DEV-LOGIN"
)

echo "ENDPOINT       | LOCAL  | PROD   | STATUS"
echo "---------------|--------|--------|--------"

local_ok=0 local_total=0 prod_ok=0 prod_total=0

for endpoint in "${!endpoints[@]}"; do
    name="${endpoints[$endpoint]}"
    
    # Test LOCAL
    local_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$LOCAL_URL$endpoint" || echo "999")
    local_size=$(curl -s --max-time $TIMEOUT "$LOCAL_URL$endpoint" | wc -c)
    [ "$local_status" = "200" ] && [ "$local_size" -gt 10 ] && local_ok=$((local_ok+1))
    local_total=$((local_total+1))
    
    # Test PROD  
    prod_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$PROD_URL$endpoint" || echo "999")
    prod_size=$(curl -s --max-time $TIMEOUT "$PROD_URL$endpoint" | wc -c)
    [ "$prod_status" = "200" ] && [ "$prod_size" -gt 10 ] && prod_ok=$((prod_ok+1))
    prod_total=$((prod_total+1))
    
    # Status indicator
    if [ "$local_status" = "200" ] && [ "$prod_status" = "200" ]; then
        status="🟢 BOTH"
    elif [ "$local_status" = "200" ]; then
        status="🟡 LOCAL"
    elif [ "$prod_status" = "200" ]; then
        status="🟠 PROD" 
    else
        status="🔴 BROKEN"
    fi
    
    printf "%-13s | %3s(%3s) | %3s(%3s) | %s\n" "$name" "$local_status" "$local_size" "$prod_status" "$prod_size" "$status"
done

echo "---------------|--------|--------|--------"
echo "SUMMARY        | ${local_ok}/${local_total} | ${prod_ok}/${prod_total} |"
echo "PROD HEALTH: $((prod_ok * 100 / prod_total))%"
echo "══════════════════════════════════════════════════════════"
