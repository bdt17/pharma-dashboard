class LandingController < ApplicationController
  def index
    @vehicles = 24.times.map do
      OpenStruct.new(
        id: "LOT-PHARMA-#{"%03d" % rand(1..999)}",
        temp: "#{rand(2.0..8.0).round(1)}°C",
        status: rand < 0.95 ? "normal" : "alert",
        eta: "#{rand(45..180)}min",
        lat: 33.4484 + rand(-1..1)/10.0,
        lng: -112.0740 + rand(-1..1)/10.0
      )
    end
  end
end
