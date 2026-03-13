namespace :render do
  task :postdeploy => :environment do
    puts "Render post-deploy complete"
  end
end
