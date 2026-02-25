#!/bin/bash
URL="https://pharma-dashboard-beq2.onrender.com"
echo "🚀 PHARMA ENTERPRISE UI TEST v16.3 - PRODUCTION MONITOR"
echo "PROD: $URL"
echo "══════════════════════════════════════════════════════════"

# Fixed: URL/name pairs only
declare -A endpoints=(
    ["/"]="HOME"
    ["/health"]="HEALTH"
    ["/vehicles"]="VEHICLES"
    ["/batches"]="BATCHES"
    ["/compliance"]="COMPLIANCE"
    ["/billing"]="BILLING"
    ["/login"]="LOGIN"
    ["/users/sign_in"]="SIGNIN"
)

passed=0 total=0

for endpoint in "${!endpoints[@]}"; do
    name="${endpoints[$endpoint]}"
    status=$(curl -s -o /dev/null -w "%{http_code}" "$URL$endpoint" || echo "999")
    size=$(curl -s --max-time 5 "$URL$endpoint" | wc -c)
    
    if [ "$status" = "200" ] && [ "$size" -gt 10 ]; then
        echo "🟢 $name $endpoint → 200 ($size bytes)"
        ((passed++))
    else
        echo "🔴 $name $endpoint → $status ($size bytes)"
    fi
    ((total++))
done

echo "══════════════════════════════════════════════════════════"
echo "📊 RESULTS: $passed/$total endpoints LIVE"
echo "✅ PRODUCTION STATUS: $((passed * 100 / total))%"
