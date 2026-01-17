require "net/http"
require "json"

namespace :gps do
  desc "Simulate GPS updates for all vehicles"
  task simulate: :environment do
    url = URI.parse("http://127.0.0.1:3000/api/v1/locations")

    puts "Starting GPS simulator… (Ctrl+C to stop)"
    loop do
      Vehicle.find_each do |v|
        lat = v.current_latitude.to_f  + rand(-0.001..0.001)
        lng = v.current_longitude.to_f + rand(-0.001..0.001)
        spd = rand(40..80)

        data = { vehicle_id: v.id, latitude: lat, longitude: lng, speed: spd }
        Net::HTTP.post(url, data.to_json, "Content-Type" => "application/json")

        v.update!(current_latitude: lat, current_longitude: lng)
        puts "Sent ping for #{v.identifier}  =>  #{lat.round(5)}, #{lng.round(5)}, #{spd}km/h"
      end
      sleep 5
    end
  end
end
