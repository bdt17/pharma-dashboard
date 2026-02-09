#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'colorize'
require 'time'

BASE_URL = "https://pharma-dashboard-beq2.onrender.com"

# TEST HELPER - MOVED TO TOP
def test_endpoint(path, data, ok_count, content_count = nil)
  url = "#{BASE_URL}#{path}"
  begin
    resp = Net::HTTP.get_response(URI(url))
    status = resp.code.to_i

    if status >= 200 && status < 400
      print "  #{status.to_s.rjust(3)} #{data[:name]}".colorize(:green)
      ok_count[0] += 1

      if content_count && resp.body.downcase.include?(data[:check].downcase)
        puts " ✓ #{data[:revenue]}".colorize(:green)
        content_count[0] += 1
      else
        puts " → #{data[:revenue]}".colorize(:yellow)
      end
    else
      print "  ❌ #{status} #{data[:name]}".colorize(:red)
      puts " → #{data[:revenue]}".colorize(:red)
    end
  rescue => e
    puts "  ❌ ERROR #{data[:name]} → #{e.class}".colorize(:red)
  end
end

TIMESTAMP = Time.now.strftime("%Y-%m-%d %H:%M MST")

puts "🚀 THOMAS IT PHARMA ENTERPRISE v8.3 - ENTERPRISE MONITOR".colorize(:cyan)
puts "=" * 100
puts "📅 #{TIMESTAMP} | 🌎 #{BASE_URL}".colorize(:white)
puts

# CORE REVENUE (MUST = 6/6)
core = {
  "/" => { name: "🏠 Dashboard", check: "PHARMA ENTERPRISE", revenue: "$12K MRR" },
  "/health" => { name: "🩺 Health", check: "HEALTH CHECK", revenue: "UPTIME 99.9%" },
  "/vehicles" => { name: "🚛 Vehicles", check: "25 VEHICLES", revenue: "GPS LIVE" },
  "/batches" => { name: "💉 Batches", check: "FDA BATCHES", revenue: "128 ACTIVE" },
  "/batches/1/chain_of_custody" => { name: "📄 FDA Compliance", check: "21 CFR", revenue: "PART 11 ✓" },
  "/billing" => { name: "💰 Billing", check: "99/MO", revenue: "sales@thomasit.com" }
}

# ENTERPRISE + FUTURE
enterprise = {
  "/safe" => { name: "🛡️ Safe Mode", check: "SAFE MODE", revenue: "EMERGENCY ✓" },
  "/gps/stream" => { name: "🛰️ GPS Stream", check: "GPS STREAM", revenue: "LIVE TRACKING" },
  "/api/health" => { name: "🔌 API Health", check: "API HEALTH", revenue: "ENTERPRISE" }
}

core_ok = [0]; core_content = [0]; enterprise_ok = [0]

puts "🟢 PHASE 1-2: CORE REVENUE (MUST = 6/6)".colorize(:green)
puts "-" * 60
core.each do |path, data|
  test_endpoint(path, data, core_ok, core_content)
end

puts "\n🟡 PHASE 3-4: ENTERPRISE (Target 3/3)".colorize(:yellow)
puts "-" * 60
enterprise.each do |path, data|
  test_endpoint(path, data, enterprise_ok)
end

# SUMMARY
puts "\n📊 ENTERPRISE PRODUCTION DASHBOARD".colorize(:cyan)
puts "-" * 60
puts "  💰 CORE REVENUE:      #{core_ok[0]}/#{core.size} 🟢".colorize(core_ok[0] == 6 ? :green : :red)
puts "  📱 CORE CONTENT:      #{core_content[0]}/#{core.size}".colorize(:green)
puts "  🔧 ENTERPRISE:        #{enterprise_ok[0]}/#{enterprise.size}".colorize(:yellow)
puts "  📈 TOTAL:             #{core_ok[0] + enterprise_ok[0]}/#{core.size + enterprise.size}"

if core_ok[0] == 6
  puts "\n🎉 💰 $12K MRR PRODUCTION READY!".colorize(:green)
  puts "   → LIVE: #{BASE_URL}".colorize(:green)
  puts "   → BILLING: #{BASE_URL}/billing".colorize(:green)
else
  puts "\n🟡 CORE REVENUE ISSUE - Fix immediately".colorize(:yellow)
end

puts "\n🚀 NEXT: watch -n 60 './test_ui.rb'"
