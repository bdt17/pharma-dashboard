#!/usr/bin/env ruby
require "net/http"
require "uri"
require "json"

BASE_URL = "https://pharma-gps-dashboard.onrender.com"
puts "🚀 THOMAS IT PHARMA ENTERPRISE v8.1 - PHASE 2 PRODUCTION STATUS"
puts "=" * 70

def test_endpoint(url, method = "GET", expected_status = 200)
  uri = URI("#{BASE_URL}#{url}")
  req = Net::HTTP::Get.new(uri) unless method == "POST"
  req = Net::HTTP::Post.new(uri) if method == "POST"
  
  begin
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    status = res.code.to_i
    if status == expected_status
      puts "✅ #{url.ljust(40)} #{status}"
      return true
    else
      puts "❌ #{url.ljust(40)} #{status} (expected #{expected_status})"
      return false
    end
  rescue => e
    puts "🔄 #{url.ljust(40)} ERROR: #{e.message}"
    return false
  end
end

# PHASE 1: CORE INFRASTRUCTURE
puts "\n🩺 PHASE 1: CORE INFRASTRUCTURE"
test_endpoint("/", "GET")
test_endpoint("/health", "GET")
test_endpoint("/vehicles", "GET")

# PHASE 2: GPS TRACKING
puts "\n🛰️ PHASE 2: GPS TRACKING"
test_endpoint("/gps/update", "POST")
test_endpoint("/gps/stream", "GET")

# PHASE 3: API ENDPOINTS
puts "\n🔌 PHASE 3: API ENDPOINTS"
test_endpoint("/api/health", "GET") if test_endpoint("/api/health", "GET", 404)
test_endpoint("/vehicles", "GET")
test_endpoint("/batches", "GET")

# LIVE GPS TESTS
puts "\n💉 LIVE GPS TESTS (Copy/paste exactly)"
puts 'curl -X POST "' + "#{BASE_URL}/gps/update?imei=GV55-001&lat=33.45&lng=-112.07\"" + '"'
puts 'curl "' + "#{BASE_URL}/gps/stream" + '"'
puts 'curl "' + "#{BASE_URL}/health" + '"'

# PRODUCTION STATUS
puts "\n🎯 PRODUCTION STATUS SUMMARY"
vehicles_count = `curl -s #{BASE_URL}/health`.match(/PHARMA OK - (\d+) vehicles/)&.captures&.first || 0
puts "  • MAIN: #{BASE_URL}"
puts "  • Vehicles Tracked: #{vehicles_count}"
mrr = vehicles_count.to_i * 99
puts "  • MRR Ready: $#{mrr}/mo (#{vehicles_count} vehicles × $99)"
puts "  • Status: #{vehicles_count.to_i > 0 ? '🟢 PRODUCTION LIVE' : '🟡 NEEDS VEHICLES'}"

puts "\n✅ All tests complete!"
puts "📧 sales@thomasinformationtechnology.com"
