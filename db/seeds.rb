User.destroy_all
User.create!(
  email: 'admin@pharmagps.com',
  password: 'P@ssw0rdPh@rm@2026!v14',
  password_confirmation: 'P@ssw0rdPh@rm@2026!v14'
)
puts "✅ Admin created: P@ssw0rdPh@rm@2026!v14"
