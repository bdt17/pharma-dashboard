namespace :two_factor do
  desc "Show a user's two-factor status: two_factor:status[user@example.com]"
  task :status, [ :email ] => :environment do |_task, args|
    user = TwoFactorReset.find_user!(args[:email])

    puts "#{user.email} (#{user.role})"
    puts "  two-factor required for this role: #{user.two_factor_required?}"
    puts "  enrolled:            #{user.otp_enabled?}"
    puts "  enrolled at:         #{user.otp_enabled_at || '-'}"
    puts "  backup codes left:   #{user.backup_codes_remaining}"
  end

  desc "Reset a user locked out of two-factor (lost authenticator + backup codes): two_factor:reset[user@example.com]"
  task :reset, [ :email ] => :environment do |_task, args|
    user = TwoFactorReset.find_user!(args[:email])

    unless user.otp_enabled? || user.otp_secret.present?
      puts "#{user.email} has no two-factor enrollment to reset. Nothing to do."
      next
    end

    print "Reset two-factor for #{user.email} (#{user.role})? This can't be undone. [y/N] "
    unless $stdin.gets.to_s.strip.casecmp("y").zero?
      puts "Aborted."
      next
    end

    result = TwoFactorReset.call(email: user.email, performed_by: "rake:two_factor:reset")

    puts "Done. Two-factor cleared for #{result.user.email} (was #{result.was_enabled ? 'enabled' : 'mid-enrollment'})."
    if result.user.two_factor_required?
      puts "They must set it up again on their next sign-in before they can use the app."
    else
      puts "They can set it up again whenever they like from the Security page."
    end
  end

  desc "Re-save every otp_secret so it's stored encrypted at rest (safe to re-run)"
  task encrypt_secrets: :environment do
    scope = User.where.not(otp_secret: nil)
    total = scope.count
    done = 0

    scope.find_each do |user|
      user.encrypt # ActiveRecord::Encryption: encrypts encryptable attrs + saves
      done += 1
    end

    puts "Re-saved otp_secret for #{done}/#{total} enrolled users -- all encrypted at rest now."
  end
end
