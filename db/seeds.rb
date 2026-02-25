User.find_or_create_by!(email: 'admin@pharmagps.com') do |u|
  u.password = 'l4XaO5ZbjHGnqXEfFbfsv3ao'
  u.password_confirmation = 'l4XaO5ZbjHGnqXEfFbfsv3ao'
end

puts "✅ Admin: admin@pharmagps.com"
puts "🔑 Password: l4XaO5ZbjHGnqXEfFbfsv3ao"
