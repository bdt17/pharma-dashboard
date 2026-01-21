#!/usr/bin/env bash
set -e

echo "🧹 Cleaning Pharma Dashboard project..."

# ---- NON-RAILS FILES (safe to remove) ----
rm -f dashboard.html
rm -f revenue.pdf coc.pdf test.pdf test2.pdf
rm -f rails.log
rm -f production.rb.backup
rm -rf pharma-test-scripts
rm -rf temp_routes
rm -rf Run Booting

# ---- DUPLICATE / STRAY CONTROLLERS ----
rm -f landing_controller.rb

# ---- CACHE / TEMP ----
rm -rf tmp/cache
rm -rf tmp/pids
rm -rf tmp/sockets

# ---- LOG FILES ----
rm -f log/development.log
rm -f log/test.log

# ---- VERIFY ----
echo
echo "✅ Cleanup complete."
echo
echo "📁 Remaining key structure:"
ls -d app config db public bin log

echo
echo "🚀 Next steps:"
echo "1) bin/rails restart"
echo "2) bin/rails server"
echo "3) Visit / and /dashboard"
