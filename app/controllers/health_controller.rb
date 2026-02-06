class HealthController < ApplicationController
  def index
    render plain: "🟢 PHARMA OK | Vehicles:#{Vehicle.count} | #{Time.now.utc}", status: :ok
  end
end
