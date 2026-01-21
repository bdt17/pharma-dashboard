class HomepageController < ApplicationController
  def index
    render plain: "PHARMA DASHBOARD LIVE 🚛💉📍 FDA REVENUE READY", status: 200
  end
  
  def revenue_test
    render plain: "FDA REVENUE LIVE ✓ Batch 1 - $12K/mo READY", status: 200
  end
end
