class HomeController < ApplicationController
  def index
    @trucks = 24.times.map do |i|
      lat = 33.4 + (rand(100)/1000.0 - 0.05)
      lng = -112.1 + (rand(100)/1000.0 - 0.05)
      alert = rand(10) > 8 ? "🚨 TEMP ALERT" : "✅ OK"
      { 
        id: i+1, 
        lat: lat, 
        lng: lng, 
        temp: rand(8.0).round(1), 
        eta: "#{10+rand(30)}min", 
        alert: alert 
      }
    end
  end
end

  def health
    render plain: "Phase 15 GPS LIVE - #{Time.now.utc} - #{@trucks.count} trucks", status: 200
  end
