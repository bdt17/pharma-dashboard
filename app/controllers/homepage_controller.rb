class HomepageController < ApplicationController
  def index
    # Renders app/views/homepage/index.html.erb + pharma dashboard layout
  end
  
  def revenue_test
    render plain: "FDA REVENUE LIVE ✓ Batch 1 - $12K/mo READY", status: 200
  end
end
