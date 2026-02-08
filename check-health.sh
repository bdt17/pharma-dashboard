#!/bin/bash
echo "=== PHARMA DASHBOARD HEALTH CHECK (Feb 2026) ==="
echo "1. Main site..."
curl -s -w "Status: %{http_code} | Time: %{time_total}s\n" \
  https://pharma-dashboard-beq2.onrender.com/

echo "2. GPS Dashboard..."
curl -s -w "Status: %{http_code} | Time: %{time_total}s\n" \
  https://pharma-gps-dashboard.onrender.com/

echo "3. PDF Chain-of-Custody..."
curl -s -w "Status: %{http_code} | Size: %{size_download}b\n" \
  "https://pharma-dashboard-beq2.onrender.com/batches" | head -1

echo "4. API Endpoints..."
curl -s -w "Status: %{http_code}\n" \
  https://pharma-dashboard-beq2.onrender.com/api/health

echo "5. Load test summary (5 users/sec x 30s)..."
echo "Target: <2s avg response time"
