class HomepageController < ApplicationController
  def index
    # Renders app/views/homepage/index.html.erb + layout
  end
  def revenue_test
    render plain: "FDA REVENUE LIVE ✓", status: 200
  end
end
