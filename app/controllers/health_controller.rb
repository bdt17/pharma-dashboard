class HealthController < ApplicationController
  def index
    render plain: "🟢 PHARMA LIVE | Trucks: #{Vehicle.count}", status: 200
  end
end
