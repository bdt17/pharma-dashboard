class GpsController < ApplicationController
  def dashboard
    @vehicles = 24.times.map do
      OpenStruct.new(
        id: "LOT-PHARMA-#{"%03d" % rand(1..999)}",
        lat: 39.8 + rand(-5..5)/10.0,
        lng: -98.5 + rand(-20..20)/10.0,
        temp: "#{rand(2.0..8.0).round(1)}°C",
        status: rand < 0.95 ? "normal" : "alert",
        eta: "#{rand(45..180)}min"
      )
    end
  end
end
