# Operator backstop for a user locked out of two-factor authentication --
# they've lost their authenticator app *and* their backup codes, so they
# can't clear the login challenge and (for an admin/pharmacist) can't
# self-disable it either. There is no in-app path for this on purpose: it
# needs someone with shell access to the production box, not a web request.
#
# Run via `bin/rails "two_factor:reset[user@example.com]"` (see
# lib/tasks/two_factor.rake). This clears the secret, the backup codes, and
# the enabled flag, and records an AuditLog entry against the affected user
# so the reset shows up in their organization's audit feed. The next time
# they sign in they start enrollment from scratch -- immediately for an
# admin/pharmacist (two_factor_required?), or at their own choosing for
# anyone else.
class TwoFactorReset
  Result = Struct.new(:user, :was_enabled, keyword_init: true)

  class UserNotFound < StandardError; end

  def self.call(...)
    new(...).call
  end

  # Shared by the service and the rake tasks. Matches Devise's
  # case-insensitive email lookup (config.case_insensitive_keys).
  def self.find_user!(email)
    normalized = email.to_s.strip
    raise UserNotFound, "No email given" if normalized.empty?

    User.find_by("LOWER(email) = ?", normalized.downcase) ||
      raise(UserNotFound, "No user with email #{normalized.inspect}")
  end

  def initialize(email:, performed_by: "console", ip_address: nil)
    @email = email.to_s.strip
    @performed_by = performed_by
    @ip_address = ip_address
  end

  def call
    user = self.class.find_user!(@email)
    was_enabled = user.otp_enabled?

    user.disable_two_factor!

    AuditLog.record!(
      event: "two_factor_reset",
      user: user,
      ip_address: @ip_address,
      data: { performed_by: @performed_by, was_enabled: was_enabled, role: user.role }
    )

    Result.new(user: user, was_enabled: was_enabled)
  end
end
