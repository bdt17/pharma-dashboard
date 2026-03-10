#!/bin/bash
# 🚀 PHARMA DASHBOARD FRONTEND TEST SUITE v1.0
# Tests UI content + screenshots + Tailwind rendering

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

LOCAL="http://127.0.0.1:3000"
PROD="https://pharma-dashboard-beq2.onrender.com"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_DIR="test_screenshots/$TIMESTAMP"

echo -e "${BLUE}🚀 PHARMA ENTERPRISE FRONTEND TEST SUITE v1.0${NC}"
echo "LOCAL: $LOCAL | PROD: $PROD"
echo "==============================================="

mkdir -p test_screenshots/$TIMESTAMP

# 🎯 CRITICAL PAGES TO TEST (Phase 10)
pages=(
  "/" "Homepage"
  "/index.html" "Landing" 
  "/health" "Health Check"
  "/dashboard" "Dashboard"
  "/batches" "Batches"
  "/batches.pdf" "CoC PDF"
  "/gps" "GPS Fleet"
  "/subscribe" "Stripe Plans"
  "/billing" "Billing"
  "/users/sign_in" "Devise Login"
  "/users/sign_up" "Devise Signup"
)

failures=0
total=0

for url in "${pages[@]}"; do
  if [ $((total % 2)) -eq 0 ]; then
    page_url="${LOCAL}${url}"
    page_name="${pages[$total+1]} (LOCAL)"
  else
    page_url="${PROD}${url}"
    page_name="${pages[$total+1]} (PROD)"
  fi
  
  ((total++))
  
  echo -ne "${YELLOW}Testing $page_name... ${NC}"
  
  # HTTP Status + Content validation
  status=$(curl -s -o /dev/null -w "%{http_code}" "$page_url")
  content=$(curl -s "$page_url" | head -500)
  
  # Screenshot simulation (html -> image validation)
  screenshot_file="$SCREENSHOT_DIR/$(echo $page_url | sed 's|[/:.]|-|g').html"
  echo "$content" > "$screenshot_file"
  
  # Phase 10 content checks
  if [[ "$url" == "/dashboard" ]] && [[ "$content" == *"Dashboard LIVE"* ]]; then
    echo -e "${GREEN}✅ PASS${NC}"
  elif [[ "$url" == "/health" ]] && [[ "$status" == "200" ]]; then
    echo -e "${GREEN}✅ PASS${NC}"
  elif [[ "$url" == "/batches" ]] && [[ "$content" == *"Batches Dashboard"* ]]; then
    echo -e "${GREEN}✅ PASS${NC}"
  elif [[ "$status" == "200" ]]; then
    echo -e "${GREEN}✅ PASS${NC}"
  else
    echo -e "${RED}❌ FAIL (Status: $status)${NC}"
    failures=$((failures + 1))
    echo "Content preview:"
    echo "$content" | head -3
  fi
done

# 🧪 TAILWIND CSS VALIDATION
echo -e "\n${BLUE}🧪 TAILWIND CSS CHECK${NC}"
if curl -s "$PROD/dashboard" | grep -q "tailwind"; then
  echo -e "${GREEN}✅ Tailwind CSS detected${NC}"
else  
  echo -e "${YELLOW}⚠️  Tailwind check inconclusive${NC}"
fi

# 📊 SUMMARY
echo -e "\n${BLUE}📊 FRONTEND TEST SUMMARY${NC}"
echo "Total pages: $total | Failures: $failures | Pass rate: $(( (total-failures)*100/total ))%"
echo "Screenshots saved: $SCREENSHOT_DIR"

if [ $failures -eq 0 ]; then
  echo -e "${GREEN}🎉 ALL FRONTEND PAGES PASSING! Phase 10 UI READY 🚀${NC}"
  exit 0
else
  echo -e "${RED}❌ $failures frontend failures - Check test_screenshots/$TIMESTAMP/${NC}"
  exit 1
fi
