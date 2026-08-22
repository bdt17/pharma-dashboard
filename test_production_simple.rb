#!/usr/bin/env ruby
BASE_URL = "https://pharma-dashboard-beq2.onrender.com"
endpoints = [ "/", "/health", "/vehicles", "/batches", "/batches/1/chain_of_custody", "/billing" ]

puts "PHARMA PRODUCTION CHECK (Text OK = Revenue Ready)\n" + "="*50
live = 0

endpoints.each do |path|
  begin
    resp = Net::HTTP.get_response(URI(BASE_URL + path))
    if resp.code.to_i == 200 && resp.body.length > 10
      puts "✅ #{path.ljust(30)} #{resp.code} (#{resp.body.length} chars)"
      live += 1
    else
      puts "❌ #{path.ljust(30)} #{resp.code}"
    end
  rescue
    puts "❌ #{path.ljust(30)} ERROR"
  end
end

puts "\nRESULT: #{live}/6 LIVE = " + (live >= 5 ? "💰 SALES READY 🚀" : "Fix needed")
puts "DEMO: #{BASE_URL}"
