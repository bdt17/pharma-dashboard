class HomepageController < ApplicationController
  def index
    render layout: false
  end
  
  def revenue_test
    render plain: "FDA REVENUE LIVE ✓", status: 200
  end
end
//CACHEBUST
