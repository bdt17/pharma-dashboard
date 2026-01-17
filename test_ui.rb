#!/usr/bin/env ruby
require 'playwright'

Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
  chromium = playwright.chromium.launch(headless: true)
  page = chromium.new_page
  
  page.goto('https://pharma-dashboard-1-9xaz.onrender.com')
  puts "📱 Title: #{page.title}"
  
  page.screenshot(path: 'pharma_dashboard.png')
  puts "✅ Screenshot: pharma_dashboard.png"
  
  # Test GPS API via browser
  gps_response = page.evaluate(<<-JS)
    fetch('/api/gps', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({lat:33.44, lng:-112.07, batch:'PFIZER-INSULIN'})
    }).then(r => r.json())
  JS
  
  puts "✅ GPS API: #{gps_response}"
  
  chromium.close
end
