# TOTP second factor for User. Devise ships no second-factor support, so this
# concern adds a small RFC 6238 layer on top of the existing password strategy:
# a per-user base32 secret (`otp_secret`), an `otp_enabled` flag, ten one-time
# backup codes stored as BCrypt digests, and a replay guard so a code that is
# still inside its validity window cannot be spent twice.
#
# Two-factor is opt-in for most roles and mandatory for the roles that can
# reach compliance records and billing (see TWO_FACTOR_REQUIRED_ROLES). The
# enforcement lives in ApplicationController#enforce_two_factor; this concern
# is just the data and the verification primitives.
module TwoFactorAuthentication
  extend ActiveSupport::Concern

  included do
    # Encrypted at rest (ActiveRecord Encryption; keys configured in
    # config/application.rb). Non-deterministic -- nothing ever queries by
    # otp_secret. Existing plaintext rows keep working while
    # support_unencrypted_data is on; `bin/rails two_factor:encrypt_secrets`
    # migrates them.
    encrypts :otp_secret
  end

  # Shown in the authenticator app next to the account. Kept here (not in a
  # locale/config file) because it is also embedded in every provisioning URI
  # and changing it would orphan already-enrolled authenticators.
  TOTP_ISSUER = "Pharma Transport".freeze

  # Roles that must enroll before reaching any authenticated page, and that
  # cannot turn two-factor back off: admins (billing, org management) and
  # pharmacists (they sign off on chain-of-custody / compliance records).
  # dispatchers and drivers are opt-in.
  TWO_FACTOR_REQUIRED_ROLES = %w[admin pharmacist].freeze

  BACKUP_CODE_COUNT = 10

  # Clock-skew allowance (in seconds) on either side of the current
  # 30-second step, so a user whose phone clock is a little off still works.
  # 30 gives roughly a 90-second window, matching what most services allow.
  OTP_DRIFT = 30

  # otpauth:// URI a QR code / manual-entry field is built from.
  def otp_provisioning_uri
    ROTP::TOTP.new(otp_secret, issuer: TOTP_ISSUER).provisioning_uri(email)
  end

  # Inline SVG (no binary, no ImageMagick) for the enrollment page.
  # viewbox: true emits a viewBox instead of fixed width/height, so the
  # view can scale it in CSS without the fuzzy non-integer bitmap downscale
  # (with shape-rendering: crispEdges) that stopped some phone cameras from
  # decoding it. The white quiet-zone the code needs is added by the view's
  # padded wrapper.
  def otp_qr_code_svg
    RQRCode::QRCode.new(otp_provisioning_uri).as_svg(
      module_size: 6, standalone: true, use_path: true, viewbox: true
    )
  end

  # Whether this user must use two-factor (and may not disable it).
  def two_factor_required?
    TWO_FACTOR_REQUIRED_ROLES.include?(role)
  end

  # Assign a secret for a not-yet-enrolled user starting setup. Only when
  # there isn't one yet: a plain reload of the setup page must NOT rotate
  # the secret out from under a phone the user has already added it to
  # (which silently breaks every code they generate). A never-confirmed
  # secret is useless to anyone but its owner, so keeping a stale one for
  # an abandoned enrolment costs nothing. No-op once enrolled.
  def generate_otp_secret!
    update!(otp_secret: ROTP::Base32.random) if otp_secret.blank? && !otp_enabled?
  end

  # Verify a 6-digit TOTP and, on success, remember its timestep so the same
  # code cannot be replayed while it is still valid. Returns true/false.
  def verify_and_consume_otp!(code)
    return false if otp_secret.blank? || code.blank?

    totp = ROTP::TOTP.new(otp_secret, issuer: TOTP_ISSUER)
    after = otp_consumed_timestep && Time.zone.at(otp_consumed_timestep)
    verified_at = totp.verify(code.to_s.strip, drift_behind: OTP_DRIFT, drift_ahead: OTP_DRIFT, after: after)
    return false unless verified_at

    update!(otp_consumed_timestep: verified_at.to_i)
    true
  end

  # Flip the user to enrolled and hand back a fresh set of backup codes (the
  # only time the plaintext codes exist). Atomic: if backup-code generation
  # fails, the enrolled flag rolls back rather than leaving a half-enrolled
  # user who can't be challenged and has no recovery codes. The security
  # notification is queued after the commit -- deliver_later so a
  # mail-provider hiccup can't fail the enrollment.
  def enable_two_factor!
    codes = transaction do
      update!(otp_enabled: true, otp_enabled_at: Time.current)
      generate_backup_codes!
    end
    TwoFactorMailer.with(user: self).enabled.deliver_later
    codes
  end

  # Turn two-factor off and clear every trace of the old secret / codes, so a
  # later re-enrollment starts clean. Callers must block this for
  # two_factor_required? users. Also covers an operator reset (TwoFactorReset),
  # so the notification always goes out.
  def disable_two_factor!
    update!(
      otp_enabled: false, otp_enabled_at: nil, otp_secret: nil,
      otp_backup_codes: nil, otp_consumed_timestep: nil
    )
    TwoFactorMailer.with(user: self).disabled.deliver_later
  end

  # Replace the backup codes with a fresh batch, returning the plaintext list
  # for one-time display. Digests (never the codes) are what gets stored.
  def generate_backup_codes!
    codes = Array.new(BACKUP_CODE_COUNT) { SecureRandom.hex(4) }
    digests = codes.map { |c| ::BCrypt::Password.create(c, cost: backup_code_bcrypt_cost).to_s }
    update!(otp_backup_codes: digests.to_json)
    codes
  end

  # Consume one backup code: returns true and removes it if it matches an
  # unused digest, false otherwise.
  def invalidate_backup_code!(code)
    return false if code.blank?

    normalized = code.to_s.strip
    digests = backup_code_digests
    match = digests.find { |digest| ::BCrypt::Password.new(digest) == normalized }
    return false unless match

    digests.delete(match)
    update!(otp_backup_codes: digests.to_json)
    true
  end

  def backup_codes_remaining
    backup_code_digests.size
  end

  # Accepts either a current TOTP or an unused backup code -- what the
  # post-password challenge screen submits.
  def verify_second_factor(code)
    verify_and_consume_otp!(code) || invalidate_backup_code!(code)
  end

  private

  def backup_code_digests
    JSON.parse(otp_backup_codes.presence || "[]")
  end

  # Backup codes are only ~32 bits of entropy, so they're bcrypt-hashed rather
  # than fast-digested. The work factor drops to the minimum under test --
  # otherwise every spec that enrolls a user pays for 10 full-cost hashes.
  def backup_code_bcrypt_cost
    Rails.env.test? ? ::BCrypt::Engine::MIN_COST : ::BCrypt::Engine::DEFAULT_COST
  end
end
