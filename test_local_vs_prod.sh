#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}🚀 PHASE 10 FULL STACK HEALTH CHECK - PHARMA TRANSPORT${NC}"
echo "LOCAL: http://127.0.0.1:3000 | PROD: https://pharma-dashboard-beq2.onrender.com"
echo "═══════════════════════════════════════════════════════════════════════════════"

LOCAL_URL="http://127.0.0.1:3000"
PROD_URL="https://pharma-dashboard-beq2.onrender.com"
TIMEOUT=10

# ALL Pharma Transport endpoints
ENDPOINTS=(
  "Homepage:/"
  "Health:/health"
  "Dashboard:/dashboard" 
  "Vehicles:/vehicles"
  "Batches:/batches"
  "Subscribe:/subscribe"
  "Billing:/billing"
  "Compliance:/compliance"
  "API Health:/api/health"
  "Debug Batches:/debug/batches"
  "CoC PDF:/batches/1/chain-of-custody.pdf"
  "CoC API:/batches/1/coc_pdf"
  "Devise Login:/users/sign_in"
  "Devise Signup:/users/sign_up"
  "GPS API:/api/v1/gps"
  "API Batches:/api/batches"
  "API Vehicles:/api/vehicles"
  "Stripe Success:/subscribe/success"
  "Temperature Log:/batches/1/temperature_log"
)

printf "\n%-20s | %-8s | %-8s | %-10s\n" "ENDPOINT" "LOCAL" "PROD" "STATUS"
printf "%-20s-+-%-8s-+-%-8s-+-%-10s\n" "--------------------" "--------" "--------" "----------"
echo

local_ok=0
prod_ok=0
total=${#ENDPOINTS[@]}

for endpoint in "${ENDPOINTS[@]}"; do
  name="${endpoint%%:*}"
  path="${endpoint##*:}"
  local_test="${LOCAL_URL}${path}"
  prod_test="${PROD_URL}${path}"
  
  printf "%-20s | " "$name"
  
  # Test LOCAL
  if curl -s -f -m $TIMEOUT "$local_test" >/dev/null 2>&1; then
    printf "${GREEN}PASS${NC:7} | "
    ((local_ok++))
  else
    printf "${RED}FAIL${NC:7} | "
  fi
  
  # Test PROD  
  if curl -s -f -L -m $TIMEOUT "$prod_test" >/dev/null 2>&1; then
    printf "${GREEN}PASS${NC:7} | "
    ((prod_ok++))
  else
    printf "${RED}FAIL${NC:7} | "
  fi
  
  # Status symbol
  if [ $local_ok -gt 0 ] || [ $prod_ok -gt 0 ]; then
    printf "${GREEN}🟢${NC}\n"
  else
    printf "${RED}🔴${NC}\n"
  fi
done

echo "─────────────────────────────────────────────────────────"
printf "SUMMARY      | %d/%d | %d/%d | %d%%/%d%%\n" \
  $local_ok $total $prod_ok $total \
  $((local_ok*100/total)) $((prod_ok*100/total))

if [ $local_ok -eq $total ] && [ $prod_ok -eq $total ]; then
  echo -e "${GREEN}🎉 ALL SYSTEMS OPERATIONAL${NC}"
  exit 0
elif [ $local_ok -eq 0 ]; then
  echo -e "${YELLOW}⚠️  START SERVER: rails s -p 3000 ${NC}"
  exit 1
else
  echo -e "${YELLOW}⚠️  PARTIAL OPERATIONAL${NC}"
  exit 2
fi
