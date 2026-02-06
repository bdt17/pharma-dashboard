class HealthController < ApplicationController
  def index
    render plain: "🟢 PHARMA DASHBOARD OK #{Time.now.utc.iso8601}", status: 200
  end
end
