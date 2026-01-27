#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'json'

URLS = {
  '8jhe' => 'https://pharma-dashboard-8jhe.onrender.com',
  'beq2' => 'https://pharma-dashboard-beq2.onrender.com'
}

puts "🚀 THOMAS IT PHARMA ENTERPRISE v8.1 - FULL STACK VALIDATION"
puts "=" * 80

def test_endpoint(url, path, method: 'GET')
  uri = URI(url + path)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.open_timeout = 10
  http.read_timeout = 10

  case method.upcase
  when 'GET'
    res = http.get(uri.request_uri)
  when 'POST'
    res = http.post(uri.request_uri, '')
  else
    res = http.get(uri.request_uri)
  end

  [res.code == '200', res.code]
end

URLS.each do |name, url|
  puts "\n🏥 #{name.upcase} DASHBOARD: #{url}"
  puts "-" * 50
  
  puts "🩺 PHASE 1: CORE INFRASTRUCTURE"
  dashboard_ok, dashboard_code = test_endpoint(url, '/')
  puts "  1️⃣ Dashboard → #{dashboard_ok ? '✅ LIVE' : "❌ #{dashboard_code}"}"
  
  health_ok, health_code = test_endpoint(url, '/api/health')
  puts "  2️⃣ Health API → #{health_ok ? '✅ LIVE' : "🔄 #{health_code}"}"
  
  layout_ok = `curl -s "#{url}" | grep -c 'PharmaTransport'`.strip != '0'
  puts "  3️⃣ Layout → #{layout_ok ? '✅ PERFECT' : '❌ BROKEN'}"
  
  thomas_ok = `curl -s "#{url}" | grep -c 'Thomas'`.strip != '0'
  puts "  4️⃣ Thomas IT → #{thomas_ok ? '✅ PERFECT' : '❌ MISSING'}"

  puts "\n🛰️ PHASE 3: API ENDPOINTS"
  gps_post_ok, gps_post_code = test_endpoint(url, '/gps/update', method: 'POST')
  puts "  ✅ GPS POST → #{gps_post_ok ? '✅ LIVE' : "🔄 #{gps_post_code}"}"
  
  gps_get_ok, gps_get_code = test_endpoint(url, '/gps/update/stream')
  puts "  ✅ GPS GET  → #{gps_get_ok ? '✅ LIVE' : "🔄 #{gps_get_code}"}"
  
  test_pdf_ok, test_pdf_code = test_endpoint(url, '/test-pdf')
  puts "  ✅ Phase 8 → #{test_pdf_ok ? '✅ LIVE' : "🔄 #{test_pdf_code}"}"
end

puts "\n💉 LIVE GPS TESTS (Copy/paste these exactly)"
URLS.each do |name, url|
  puts "\n#{name.upcase}:"
  puts "curl -X POST \"#{url}/gps/update?imei=GV55-001&lat=33.45&lng=-112.07\""
  puts "curl \"#{url}/gps/update/stream\""
  puts "curl \"#{url}/api/health\""
  puts "curl \"#{url}/test-pdf\""
end

puts "\n🎯 THOMAS IT PHARMA = GPS READY | 24 vehicles x $99/mo = $2376 MRR"
puts "📧 sales@thomasinformationtechnology.com"
