class DashboardController < ApplicationController
  def index
    render file: 'app/views/dashboard/index.html.erb', layout: false
  end
end
