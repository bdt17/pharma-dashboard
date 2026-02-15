#!/usr/bin/env ruby
# Run: ruby test_rails.rb
# Diagnoses Rails DB/migration issues WITHOUT modifying anything

require_relative "config/environment"
require 'active_record'

ENV['RAILS_ENV'] ||= 'production'

puts "=== RAILS DIAGNOSTIC REPORT (#{Rails.env}) ==="
puts "Rails version: #{Rails.version}"
puts "DB config: #{ActiveRecord::Base.connection_config.configuration_hash.slice(:adapter, :database)}"
puts

# 1. LIST ALL MIGRATIONS (timestamp order)
puts "📋 MIGRATIONS FOUND (#{Dir['db/migrate/*.rb'].size}):"
migrations = Dir['db/migrate/*.rb'].sort.map { |f| File.basename(f, '.rb') }
migrations.each_with_index do |migration, i|
  puts "  #{i+1}. #{migration}"
end
puts

# 2. CHECK DEPENDENCIES in each migration
puts "🔍 MIGRATION DEPENDENCY CHECK:"
broken_deps = []
migrations.each do |migration|
  path = "db/migrate/#{migration}.rb"
  next unless File.exist?(path)
  
  content = File.read(path)
  refs = content.scan(/t\.references?[:\s]+:(\w+)/).flatten
  creates = content.match(/create_table[:\s]+["'](\w+)["']/)&.captures&.first
  creates ||= content.match(/create_table\s+\(["'](\w+)["']/i)&.captures&.first
  
  if creates && refs.any?
    puts "  #{migration}: creates=#{creates} → refs=#{refs.join(',')}"
    refs.each do |ref|
      broken_deps << "#{migration} expects #{ref} (create_table :#{ref} missing?)" unless migrations.any? { |m| m.match?(/create_#{ref}/i) }
    end
  end
end
puts

# 3. RECOMMENDED FIX ORDER
puts "✅ RECOMMENDED MIGRATION ORDER:"
base_tables = %w[pharmacies vehicles drivers batches locations location_points]
base_tables.each do |table|
  mig = migrations.find { |m| m.match?(/create_#{table}/i) }
  status = mig ? "✅ #{mig}" : "❌ CREATE #{table.upcase}"
  puts "  #{status}"
end
puts

if broken_deps.any?
  puts "🔥 BROKEN DEPENDENCIES:"
  broken_deps.each { |dep| puts "  #{dep}" }
else
  puts "✅ No obvious dependency issues"
end

puts "\n🎯 NEXT STEPS:"
puts "1. Create missing tables shown above"
puts "2. RAILS_ENV=production rails db:migrate"
puts "3. ruby test_rails.rb (verify fixed)"
