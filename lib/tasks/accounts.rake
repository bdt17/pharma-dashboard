namespace :accounts do
  desc <<~DESC
    Create a ready-to-use account (shell only). Skips the public signup flow --
    the user is created already confirmed, so it works without a mail provider.

      bin/rails "accounts:create[you@example.com,Acme Pharmacy]"
      ROLE=dispatcher PASSWORD=secret123 bin/rails "accounts:create[dev@example.com,Acme Pharmacy]"

    ROLE defaults to admin. Admins and pharmacists still have to enrol two-factor
    on first sign-in (mandatory for those roles) -- create a dispatcher if you
    want to skip straight past that. PASSWORD is generated and printed if unset.
  DESC
  task :create, [ :email, :organization ] => :environment do |_task, args|
    email = args[:email].to_s.strip
    org_name = args[:organization].to_s.strip
    abort "Usage: accounts:create[email,organization]" if email.empty? || org_name.empty?
    abort "A user with #{email} already exists." if User.exists?([ "LOWER(email) = ?", email.downcase ])

    role = (ENV["ROLE"].presence || "admin")
    unless User.roles.key?(role)
      abort "ROLE must be one of: #{User.roles.keys.join(', ')}"
    end

    password = ENV["PASSWORD"].presence || SecureRandom.alphanumeric(16)
    organization = Organization.find_or_create_by!(name: org_name)

    user = User.create!(
      email: email, password: password, organization: organization, role: role
    )
    # confirmed_at is set by User#auto_confirm_unless_self_service_signup when
    # requires_email_confirmation was never flagged (i.e. not the signup form).

    puts "Created #{user.email} (#{user.role}) in organization #{organization.name} (id #{organization.id})"
    puts "Password: #{password}" unless ENV["PASSWORD"].present?
    puts "Two-factor: required on first sign-in for this role." if user.two_factor_required?
  end

  desc "Confirm an existing (unconfirmed) account: accounts:confirm[you@example.com]"
  task :confirm, [ :email ] => :environment do |_task, args|
    user = find_user!(args[:email])
    if user.confirmed?
      puts "#{user.email} is already confirmed."
    else
      user.confirm
      puts "Confirmed #{user.email}."
    end
  end

  desc "Show an account's status: accounts:info[you@example.com]"
  task :info, [ :email ] => :environment do |_task, args|
    user = find_user!(args[:email])
    puts "#{user.email}"
    puts "  organization:   #{user.organization&.name} (id #{user.organization_id})"
    puts "  role:           #{user.role}"
    puts "  confirmed:      #{user.confirmed? ? user.confirmed_at.iso8601 : 'no'}"
    puts "  two-factor:     #{user.otp_enabled? ? 'enrolled' : 'not enrolled'} (required: #{user.two_factor_required?})"
    puts "  locked:         #{user.access_locked? ? 'yes' : 'no'}"
    subscription = user.organization&.subscriptions&.order(created_at: :desc)&.first
    puts "  subscription:   #{subscription ? "#{subscription.status} (#{subscription.tier || 'no tier'})" : 'none'}"
  end

  def find_user!(email)
    normalized = email.to_s.strip
    abort "No email given" if normalized.empty?
    User.find_by("LOWER(email) = ?", normalized.downcase) || abort("No user with email #{normalized.inspect}")
  end
end
