class HomeController < ApplicationController
  def index
    @trucks = 24.times.map do |i|
      alert: rand(10) > 8 ? "🚨 TEMP ALERT" : "✅ OK"
      lat = 33.4 + (rand(100)/1000.0 - 0.05)
      lng = -112.1 + (rand(100)/1000.0 - 0.05)
      { id: i+1, lat: lat, lng: lng, temp: "#{rand(8.0)}", eta: "#{10+rand(30)}min" }
    end
    render :index
  end
end
