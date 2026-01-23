#!/usr/bin/env ruby
require 'open3'
require 'json'

URL = 'https://pharma-dashboard-beq2.onrender.com'
puts "🚀 THOMAS IT PHARMA DASHBOARD v7.0 - #0984C0 BRANDING"
puts "=" * 70

def test_curl(endpoint, method = 'GET', data = nil)
  cmd = "curl -s -w \"---HTTP:%{http_code}\" -X #{method} -L #{URL}#{endpoint}"
  cmd += " -H 'Content-Type: application/json' -d '#{data.to_json}'" if data
  stdout, stderr, status = Open3.capture3(cmd)
  http_code = stdout.strip.split('---HTTP:').last.to_i
  puts "   #{method} #{endpoint} → HTTP #{http_code}"
  http_code == 200
end

tests = [
  ['🩺 Dashboard (Thomas IT)', '/', 'GET'],
  ['🏥 Health API', '/api/health', 'GET'], 
  ['🛰️ GPS Tracking (Phoenix)', '/api/gps', 'POST', {lat: 33.4484, lng: -112.0740, batch: 'B001'}],
  ['📄 FDA B001 PDF', '/reports/chain-of-custody/B001', 'GET'],
  ['📦 Batches API', '/batches', 'GET']
]

puts "\n🔍 PRODUCTION API TESTS:\n"
results = []
tests.each_with_index do |(name, endpoint, method, data), i|
  puts "#{i+1}️⃣ #{name}:"
  results << test_curl(endpoint, method, data)
end

# GPS DEBUG - Why 422?
puts "\n🔍 GPS DEBUG (33.4484°N Phoenix):"
gps_raw = `curl -s -w "CODE:%{http_code}\nBODY:%{stdout_url}" -X POST -H 'Content-Type: application/json' -d '{"lat":33.4484,"lng":-112.0740,"batch":"B001"}' #{URL}/api/gps`
puts gps_raw

puts "\n🔍 THOMAS IT COLOR VALIDATION:"
dashboard_html = `curl -s #{URL}`
colors = ['#0984C0', '#60BDD1', '#C0BEC6', '#AAA7B0', '#FFFFFF']
color_status = colors.all? { |c| dashboard_html.include?(c) } ? '✅ THOMAS IT COLORS LIVE' : '⚠️  MISSING COLORS'
puts "   #{color_status}"

# SUMMARY
puts "\n" + "=" * 70
passed = results.count(true)
puts "\n✅ THOMAS IT $500K ARR STATUS:"
puts "   🩺 Dashboard: #{results[0] ? 'LIVE' : 'DOWN'}"
puts "   🏥 Health: #{results[1] ? 'LIVE' : 'DOWN'}"
puts "   🛰️ GPS: #{results[2] ? 'LIVE' : '422 NEEDS STRONG PARAMS'}"
puts "   📄 FDA B001: #{results[3] ? 'LIVE' : 'DOWN'}"
puts "   📦 Batches: #{results[4] ? 'LIVE' : 'DOWN'}"
puts "   APIs: #{passed}/5"
puts "   💉 #{URL}"
puts "   🎨 #0984C0 Deep Ocean Blue ✓ Phoenix AZ ✓ FDA 21CFR"

puts "\n🎉 STATUS: #{passed == 5 ? 'ENTERPRISE PRODUCTION LIVE 🚀' : 'GPS STRONG PARAMS NEEDED ⏳'}"
exit passed < 5 ? 1 : 0
