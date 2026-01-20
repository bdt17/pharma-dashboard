class HomeController < ApplicationController
  def index
    @trucks = Truck.all.presence || generate_trucks
    @trucks_count = @trucks.count
  end

  def health
    render plain: "Phase 16 READY - #{Truck.table_exists? ? Truck.count : 0} trucks - #{Time.now.utc}", status: 200
  end

  private

  def generate_trucks
    24.times.map do |i|
      lat = 33.4 + (rand(100)/1000.0 - 0.05)
      lng = -112.1 + (rand(100)/1000.0 - 0.05)
      alert = rand(10) > 8 ? "🚨 TEMP ALERT" : "✅ OK"
      { id: i+1, lat: lat, lng: lng, temp: rand(8.0).round(1), eta: "#{10+rand(30)}min", alert: alert }
    end
  end
end
