class HealthController < ApplicationController
  def index
    render plain: "🟢 PHARMA LIVE | Trucks:#{Vehicle.count} | #{Time.now}", status: 200
  end
end
