#!/bin/bash
BEQ2_BASE="https://pharma-dashboard-beq2.onrender.com"
JHE8_BASE="https://pharma-dashboard-8jhe.onrender.com"

# Check if JHE8 responds (timeout 3s)
if curl -s -m 3 "$JHE8_BASE" > /dev/null; then
  ./test_production_full.rb
else
  echo "🚀 BEQ2 ONLY MODE (JHE8 offline)"
  echo "BEQ2: $BEQ2_BASE → LIVE ✓"
  curl -s -w "dashboard: %{http_code} %{size_download}b/%{time_total}s\n" "$BEQ2_BASE/" 
  curl -s -w "health: %{http_code} %{size_download}b/%{time_total}s\n" "$BEQ2_BASE/api/health"
  curl -s -X POST -w "gps_post: %{http_code} %{size_download}b/%{time_total}s\n" "$BEQ2_BASE/gps_post" 
  curl -s -w "gps_stream: %{http_code} %{size_download}b/%{time_total}s\n" "$BEQ2_BASE/gps_stream"
  curl -s -w "test_pdf: %{http_code} %{size_download}b/%{time_total}s\n" "$BEQ2_BASE/test_pdf"
fi
