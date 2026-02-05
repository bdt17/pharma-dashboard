class DashboardController < ApplicationController
  def index
    render inline: "<h1>🚀 PHARMA DASHBOARD v8.1 LIVE</h1><p>#{Time.now}</p>", layout: false
  end
end
