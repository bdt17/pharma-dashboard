#!/bin/bash

#
# Local test script for Pharma Transport Rails app
#

# You can change this if you ever run rails server -p 3000
PORT=10000
BASE="http://127.0.0.1:$PORT"

pages=(
  "${BASE}/"
  "${BASE}/users/sign_in"
)

echo "🧪 Testing local Pharma Transport pages on $BASE"

for page in "${pages[@]}"; do
  echo -e "\nGET $page"
  status=$(curl -s -o /dev/null -w "%{http_code}" "$page")
  if [ "$status" = "200" ]; then
    echo "✅ $status"
  else
    echo "❌ $status"
  fi

  # Also do a fast HEAD check on common assets to spot 404s
  if [ "$page" = "${BASE}/" ]; then
    echo "HEAD $BASE/stylesheets/application.css (expected 404 OK)"
    asset_status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/stylesheets/application.css")
    echo "$asset_status"
  fi
done

echo -e "\nTest done."
