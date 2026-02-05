#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'

MAIN_URL = "https://pharma-gps-dashboard.onrender.com"

def check_status(url, desc)
  begin
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    status = case response.code
             when "200" then "✅ LIVE"
             when "404" then "🔄 ROUTE MISSING" 
             else "❌ #{response.code}"
             end
    puts "#{desc.ljust(30)} #{status} (#{response.code})"
  rescue => e
    puts "#{desc.ljust(30)} ❌ ERROR: #{e.message}"
  end
end

puts "🚀 THOMAS IT PHARMA ENTERPRISE v8.1 - PRODUCTION STATUS"
puts "=" * 70

puts "\n🩺 PHASE 1: CORE INFRASTRUCTURE"
check_status("#{MAIN_URL}/", "🏥 Dashboard")
check_status("#{MAIN_URL}/api/health", "🩺 Health API") 
check_status("#{MAIN_URL}/rails/active_storage", "📤 File Upload")

puts "\n🛰️ PHASE 2: GPS TRACKING" 
check_status("#{MAIN_URL}/gps/vehicles", "🚛 GPS Vehicles")
check_status("#{MAIN_URL}/gps/batches", "💉 GPS Batches")

puts "\n🔌 PHASE 3: API ENDPOINTS"
check_status("#{MAIN_URL}/api/health", "✅ Health Check")
check_status("#{MAIN_URL}/api/vehicles", "✅ Vehicles API") 
check_status("#{MAIN_URL}/api/batches", "✅ Batches API")

puts "\n💉 LIVE GPS TESTS (Copy/paste these exactly)"
puts "curl -X POST \"#{MAIN_URL}/gps/update?imei=GV55-001&lat=33.45&lng=-112.07\""
puts "curl \"#{MAIN_URL}/gps/stream\""
puts "curl \"#{MAIN_URL}/api/health\""

puts "\n🎯 STATUS SUMMARY"
puts "  • MAIN: #{MAIN_URL}"
puts "  • Revenue Ready: 25 vehicles × $99/mo = $2,475 MRR"
puts "  • Next: Google Maps API → Live Markers"
puts "📧 sales@thomasinformationtechnology.com"
