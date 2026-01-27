# lib/tasks/create_users.rake
# Thomas IT Pharma Transport - Admin User Management
namespace :pharma do
  desc "Create or update pharma transport users (admin/driver/pharmacist)"
  task users: :environment do
    puts "💉 PharmaTransport User Management - Thomas IT Phoenix AZ"
    puts "=" * 60
    
    # Master admin (full access)
    admin = User.find_or_initialize_by(email: 'admin@thomasinformationtechnology.com')
    admin.update!(
      email: 'admin@thomasinformationtechnology.com',
      password: 'Pharma2026!',
      password_confirmation: 'Pharma2026!',
      role: 'admin',
      first_name: 'Thomas',
      last_name: 'IT Admin',
      phone: '+16025551234',
      active: true
    )
    puts "✅ ADMIN: #{admin.email} (role: #{admin.role})"

    # Driver accounts
    drivers = [
      {email: 'driver1@pharmatransport.com', first_name: 'Mike', last_name: 'Johnson', role: 'driver', phone: '+16025551212'},
      {email: 'driver2@pharmatransport.com', first_name: 'Sarah', last_name: 'Chen', role: 'driver', phone: '+16025551213'},
      {email: 'driver3@pharmatransport.com', first_name: 'Carlos', last_name: 'Rodriguez', role: 'driver', phone: '+16025551214'}
    ]
    
    drivers.each do |d|
      user = User.find_or_initialize_by(email: d[:email])
      user.update!(
        email: d[:email],
        password: 'Driver2026!',
        password_confirmation: 'Driver2026!',
        role: d[:role],
        first_name: d[:first_name],
        last_name: d[:last_name],
        phone: d[:phone],
        active: true
      )
      puts "✅ DRIVER: #{user.email} (#{user.first_name} #{user.last_name})"
    end

    # Pharmacist accounts
    pharmacists = [
      {email: 'pharm1@pharmatransport.com', first_name: 'Dr. Emily', last_name: 'Davis', role: 'pharmacist', phone: '+16025551215'},
      {email: 'pharm2@pharmatransport.com', first_name: 'Dr. Raj', last_name: 'Patel', role: 'pharmacist', phone: '+16025551216'}
    ]
    
    pharmacists.each do |p|
      user = User.find_or_initialize_by(email: p[:email])
      user.update!(
        email: p[:email],
        password: 'Pharm2026!',
        password_confirmation: 'Pharm2026!',
        role: p[:role],
        first_name: p[:first_name],
        last_name: p[:last_name],
        phone: p[:phone],
        active: true
      )
      puts "✅ PHARM: #{user.email} (#{user.first_name} #{user.last_name})"
    end

    puts "\n🎉 #{User.count} total users created/updated!"
    puts "🔑 Default passwords: Admin=Pharma2026!, Driver=Driver2026!, Pharm=Pharm2026!"
  end

  desc "Reset password for specific user"
  task :reset_password, [:email] => :environment do |t, args|
    user = User.find_by(email: args[:email])
    if user
      user.update!(
        password: 'Reset2026!',
        password_confirmation: 'Reset2026!',
        last_sign_in_at: nil
      )
      puts "✅ Password reset for #{user.email}"
    else
      puts "❌ User not found: #{args[:email]}"
    end
  end

  desc "List all active users"
  task list: :environment do
    puts "Active PharmaTransport Users:"
    puts "=" * 50
    User.where(active: true).find_each do |user|
      puts "#{user.role.upcase.ljust(10)} | #{user.email.ljust(30)} | #{user.first_name} #{user.last_name}"
    end
  end
end
