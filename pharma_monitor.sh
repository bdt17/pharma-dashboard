#!/bin/bash
echo "=== $(date) PHARMA DASHBOARD HEALTH ==="
BASE="https://pharma-dashboard-beq2.onrender.com"
for p in "" health vehicles batches compliance billing "users/sign_in" "users/sign_up"; do
  code=$(curl -s -o/dev/null -w "%{http_code}" -m 10 "$BASE/$p")
  [[ $code == 200 ]] && echo "✅ $p ($code)" || echo "❌ $p ($code)"
done
echo "======================================"
