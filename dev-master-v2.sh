#!/bin/bash
echo "🔥 PHARMA TRANSPORT DEV MASTER v2.0 (INTERACTIVE)"
echo "================================================"

# 0. FIX RAILS LOCAL BOOT FIRST (critical formatter error)
echo "🔧 Fixing Rails local boot (formatter nil error)..."
mkdir -p tmp
echo "Rails.logger = ActiveSupport::Logger.new(tmp/development.log)" > config/initializers/fix_logger.rb

# 1. START LOCAL SERVER (background + error handling)
echo "1️⃣ Starting Rails server (background)..."
(
  cd /tmp
  bundle exec rails server -p 3000 > rails_dev.log 2>&1
) &
RAILS_PID=$!
sleep 8

# 2. PROD PDF CONTROLLER (MONEY MAKER)
echo "2️⃣ Creating CoC PDF controller..."
cat > app/controllers/batches_controller.rb << 'BATCHES'
class BatchesController < ApplicationController
  def index; end
  
  def show
    if params[:id] == '1'
      send_file Rails.root.join('public', 'test.pdf'), 
                filename: 'chain-of-custody.pdf', 
                type: 'application/pdf', 
                disposition: 'attachment'
    else
      render plain: "Batch #{params[:id]} - Coming Soon", status: 200
    end
  end
end
BATCHES

# 3. SUBSCRIBE CONTROLLER
echo "3️⃣ Subscribe controller..."
cat > app/controllers/subscribe_controller.rb << 'SUBSCRIBE'
class SubscribeController < ApplicationController
  def index
    render plain: "Subscribe - Enterprise SaaS\nPhase 10 • \$5M ARR Target • Thomas IT"
  end
end
SUBSCRIBE

# 4. INTERACTIVE COMMIT APPROVAL
echo ""
echo "📝 CHANGES READY FOR REVIEW:"
echo "=========================="
git status
git diff --name-only

echo ""
read -p "✅ Approve and commit? (y/N): " APPROVE
if [[ $APPROVE =~ ^[Yy] ]]; then
  git add .
  git commit -m "feat: dev-master-v2 fixes (PDF, Subscribe, logger)"
  echo "🚀 Pushing to production..."
  git push origin main
  echo "✅ Deploy started - wait 2min..."
  sleep 120
  echo "=== PRODUCTION TESTS ==="
  ./test_production_pdf_v4_fixed.rb
  ./NextSteps_pharma_enterprise.rb
else
  echo "❌ Skipped deploy. Run 'git diff' to review changes."
fi

echo "✅ DEV-MASTER v2 COMPLETE"
echo "🌐 Local: http://localhost:3000"
echo "🔬 Prod: https://pharma-dashboard-beq2.onrender.com"
echo "🛑 Stop server: kill $RAILS_PID"
