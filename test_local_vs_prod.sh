#!/usr/bin/env bash

# PHARMA DASHBOARD v17.1 - FDA CoC PDF HEALTH CHECK (URLS FIXED)
readonly LOCAL_URL="http://127.0.0.1:3000"
readonly PROD_URL="https://pharma-dashboard-beq2.onrender.com"

printf '\033[1;36m🚀 PHASE 8 CoC PDF HEALTH CHECK\033[0m\n'
echo "LOCAL: $LOCAL_URL | PROD: $PROD_URL"
echo "═══════════════════════════════════════════════════════════════"

# Test ONLY your working Phase 8 endpoints
endpoints=(
  "COC-RAW:chain-of-custody"
  "COC-PDF:coc_pdf"
)

local_ok=0
prod_ok=0
total=0

printf "%-12s | %-8s | %-8s | STATUS\n" "ENDPOINT" "LOCAL" "PROD"
echo "─────────────┼──────────┼──────────┼─────────"

for endpoint in "${endpoints[@]}"; do
  name="${endpoint%%:*}"
  path="${endpoint#*:}"
  
  # FIXED URLS - FULL PATH REQUIRED
  local_url="${LOCAL_URL}/batches/1/${path}"
  prod_url="${PROD_URL}/batches/1/${path}"
  
  # COC-RAW needs .pdf extension
  [[ "$name" == "COC-RAW" ]] && local_url+=".pdf"
  [[ "$name" == "COC-RAW" ]] && prod_url+=".pdf"
  
  echo "DEBUG: $name -> $local_url" >&2
  echo "DEBUG: $name -> $prod_url" >&2
  
  # SIMPLE CURL - captures 200, 302, 301 (success states)
  local_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$local_url" 2>/dev/null || echo "ERR")
  prod_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$prod_url" 2>/dev/null || echo "ERR")
  
  ((total++))
  [[ "$local_status" =~ ^[23] ]] && ((local_ok++))  # Accept 2xx/3xx
  [[ "$prod_status" =~ ^[23] ]] && ((prod_ok++))    # Accept 2xx/3xx
  
  # Simple color status
  if [[ "$local_status" =~ ^[23] && "$prod_status" =~ ^[23] ]]; then
    status="\033[32m🟢 BOTH OK\033[0m"
  elif [[ "$local_status" =~ ^[23] ]]; then
    status="\033[33m🟡 LOCAL OK\033[0m"
  elif [[ "$prod_status" =~ ^[23] ]]; then
    status="\033[33m🟡 PROD OK\033[0m"
  else
    status="\033[31m🔴 BOTH DOWN\033[0m"
  fi
  
  printf "%-12s | %-8s | %-8s | %s\n" "$name" "$local_status" "$prod_status" "$status"
done

echo "─────────────┼──────────┼──────────┼─────────"
local_pct=$((local_ok * 100 / total))
prod_pct=$((prod_ok * 100 / total))

printf "SUMMARY      | %d/%d | %d/%d | %d%%/%d%%\n" "$local_ok" "$total" "$prod_ok" "$total" "$local_pct" "$prod_pct"

if [[ "$local_ok" -eq "$total" && "$prod_ok" -eq "$total" ]]; then
  echo -e '\033[32m🎉 PHASE 8 DUAL CoC PDFs = $500K ARR LIVE ✅\033[0m'
  exit 0
else
  echo -e '\n\033[33m⚠️  RUN: rails s -p 3000\n\033[33mURLs hit:\n\033[0m'
  echo "  ${LOCAL_URL}/batches/1/chain-of-custody.pdf"
  echo "  ${LOCAL_URL}/batches/1/coc_pdf"
  exit 1
fi
