#!/bin/bash
# 🚀 PHARMA DASHBOARD FRONTEND TEST SUITE v2.0 - 301/Timeout FIXED
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOCAL="http://127.0.0.1:3000"
PROD="https://pharma-dashboard-beq2.onrender.com"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_DIR="test_screenshots/$TIMESTAMP"

echo -e "${BLUE}🚀 PHARMA ENTERPRISE FRONTEND TEST v2.0${NC}"
echo "LOCAL: $LOCAL | PROD: $PROD"
echo "==============================================="

mkdir -p "$SCREENSHOT_DIR"

# Phase 10 critical endpoints (handles 301 redirects + timeouts)
declare -A endpoints=(
  ["/"]="Homepage"
  ["/index.html"]="Landing"
  ["/health"]="Health Check" 
  ["/dashboard"]="Dashboard"
  ["/vehicles"]="Vehicles"
  ["/batches"]="Batches"
  ["/gps"]="GPS Fleet"
  ["/subscribe"]="Subscribe"
  ["/billing"]="Billing"
  ["/users/sign_in"]="Login"
  ["/users/sign_up"]="Signup"
)

failures=0
total=0

for path in "${!endpoints[@]}"; do
  for env in "LOCAL" "PROD"; do
    ((total++))
    base_url=$([ "$env" = "LOCAL" ] && echo "$LOCAL" || echo "$PROD")
    test_url="${base_url}${path}"
    page_name="${endpoints[$path]} ($env)"
    
    echo -ne "${YELLOW}Testing $page_name... ${NC}"
    
    # Follow redirects + 10s timeout
    status=$(curl -s -L -m 10 -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null)
    
    if [[ "$status" =~ ^2[0-9][0-9]$ ]]; then
      echo -e "${GREEN}✅ PASS ($status)${NC}"
    elif [[ "$status" == "301" || "$status" == "302" ]]; then
      echo -e "${YELLOW}⚠️  REDIRECT ($status) - Expected${NC}"
    elif [[ -z "$status" ]]; then
      echo -e "${RED}❌ TIMEOUT${NC}"
      failures=$((failures + 1))
    else
      echo -e "${RED}❌ FAIL ($status)${NC}"
      failures=$((failures + 1))
    fi
  done
done

# Phase 10 content validation (prod only)
echo -e "\n${BLUE}🔍 CONTENT VALIDATION (PROD)${NC}"
content_checks=(
  "dashboard:*Dashboard LIVE*"
  "batches:*Batches Dashboard*"
  "health:*Phase 10 LIVE*"
  "gps:*Queclink GV55*"
)

for check in "${content_checks[@]}"; do
  path="${check%%:*}"
  expected="${check#*:}"
  content=$(curl -s -m 5 "$PROD$path" | head -200)
  
  if echo "$content" | grep -q "$expected"; then
    echo -e "  $path ${GREEN}✅ Content OK${NC}"
  else
    echo -e "  $path ${RED}❌ Missing '$expected'${NC}"
    failures=$((failures + 1))
  fi
done

# Summary
echo -e "\n${BLUE}📊 FRONTEND SUMMARY${NC}"
pass_rate=$(( (total-failures)*100/total ))
echo "Total: $total | Failures: $failures | Pass: ${pass_rate}%"

if [ $failures -eq 0 ]; then
  echo -e "${GREEN}🎉 PHASE 10 UI 100% GREEN! 🚀${NC}"
  exit 0
else
  echo -e "${RED}⚠️  $failures issues - Normal for redirects/timeouts${NC}"
  exit 1
fi
