# lib/tasks/create_users.rake - Thomas IT Pharma Transport
namespace :pharma do
  desc "Create pharma transport users (admin/driver/pharmacist)"
  task users: :environment do
    puts "💉 PharmaTransport User Management - Thomas IT Phoenix AZ"
    puts "=" * 60

    # Method handles ANY User model (Devise/custom)
    def create_or_update_user(email, password, role: 'user', **attrs)
      user = User.find_or_initialize_by(email: email)
      
      # Handle different password fields
      if user.respond_to?(:password=)
        user.password = password
        user.password_confirmation = password
      elsif user.respond_to?(:encrypted_password=)
        user.encrypted_password = Digest::SHA256.hexdigest(password)
      else
        user.password_digest ||= BCrypt::Password.create(password)
      end
      
      user.update!(attrs.merge(role: role, active: true))
      puts "✅ #{role.upcase}: #{email}"
      user
    end

    # Admin
    create_or_update_user(
      'admin@thomasinformationtechnology.com', 
      'Pharma2026!',
      role: 'admin',
      first_name: 'Thomas', 
      last_name: 'IT Admin',
      phone: '+16025551234'
    )

    # Drivers
    %w[
      driver1@pharmatransport.com Mike Johnson +16025551212
      driver2@pharmatransport.com Sarah Chen +16025551213
      driver3@pharmatransport.com Carlos Rodriguez +16025551214
    ].each_slice(3) do |email, first, last, phone|
      create_or_update_user(email, 'Driver2026!', role: 'driver', 
        first_name: first, last_name: last, phone: phone)
    end

    # Pharmacists
    %w[
      pharm1@pharmatransport.com "Dr. Emily" Davis +16025551215
      pharm2@pharmatransport.com "Dr. Raj" Patel +16025551216
    ].each_slice(3) do |email, first, last, phone|
      create_or_update_user(email, 'Pharm2026!', role: 'pharmacist', 
        first_name: first, last_name: last, phone: phone)
    end

    puts "\n🎉 #{User.count} users ready!"
    puts "🔑 Passwords: Admin=Pharma2026! | Driver=Driver2026! | Pharm=Pharm2026!"
  end

  desc "Reset user password"
  task :reset_password, [:email] => :environment do |t, args|
    user = User.find_by(email: args[:email])
    if user
      new_pass = 'Reset2026!'
      
      if user.respond_to?(:password=)
        user.password = new_pass
        user.password_confirmation = new_pass
      elsif user.respond_to?(:encrypted_password=)
        user.encrypted_password = Digest::SHA256.hexdigest(new_pass)
      else
        user.password_digest = BCrypt::Password.create(new_pass)
      end
      
      user.save!
      puts "✅ #{user.email} → Reset2026!"
    else
      puts "❌ User not found: #{args[:email]}"
    end
  end

  desc "List users"
  task list: :environment do
    puts "\nActive Users:"
    User.where(active: true).find_each do |u|
      puts "#{u.role.upcase.ljust(12)} | #{u.email.ljust(30)} | #{u.first_name} #{u.last_name}"
    end
  end
end
