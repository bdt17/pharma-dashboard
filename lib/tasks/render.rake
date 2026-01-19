namespace :render do
  task prepare: :environment do
    puts "=== Running Render database setup ==="
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['solid_cache:create'].invoke
    Rake::Task['solid_queue:create'].invoke
    Rake::Task['solid_cable:create'].invoke
    puts "✅ All databases prepared"
  end
end
