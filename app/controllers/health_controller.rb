class HealthController < ApplicationController
  def index
    render plain: "🩺 PHARMA OK - #{Vehicle.count} vehicles tracked"
  end
end
