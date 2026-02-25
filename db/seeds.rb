User.find_or_create_by!(email: 'admin@pharmagps.com') do |user|
  user.password = 'Pharma2026$trongPass!'
  user.password_confirmation = 'Pharma2026$trongPass!'
end
puts "✅ Admin created: admin@pharmagps.com / Pharma2026$trongPass!"
