# TOTP second factor for User. Devise ships no second-factor support, so this
# concern adds a small RFC 6238 layer on top of the existing password strategy:
# a per-user base32 secret (`otp_secret`), an `otp_enabled` flag, ten one-time
# backup codes stored as BCrypt digests, and a replay guard so a code that is
# still inside its validity window cannot be spent twice.
#
# The enforcement that actually makes this required for every user lives in
# ApplicationController#enforce_two_factor; this concern is just the data and
# the verification primitives.
module TwoFactorAuthentication
  extend ActiveSupport::Concern

  # Shown in the authenticator app next to the account. Kept here (not in a
  # locale/config file) because it is also embedded in every provisioning URI
  # and changing it would orphan already-enrolled authenticators.
  TOTP_ISSUER = "Pharma Transport".freeze

  BACKUP_CODE_COUNT = 10

  # Small clock-skew allowance (in seconds) on either side of the current
  # 30-second step, so a user whose phone clock is slightly off still works.
  OTP_DRIFT = 15

  # otpauth:// URI a QR code / manual-entry field is built from.
  def otp_provisioning_uri
    ROTP::TOTP.new(otp_secret, issuer: TOTP_ISSUER).provisioning_uri(email)
  end

  # Inline SVG (no binary, no ImageMagick) for the enrollment page.
  def otp_qr_code_svg
    RQRCode::QRCode.new(otp_provisioning_uri).as_svg(
      module_size: 4, standalone: true, use_path: true
    )
  end

  # Assign a fresh secret for a not-yet-enrolled user starting setup. A no-op
  # once two-factor is enabled, so hitting the setup page again can never
  # silently rotate the secret out from under a working authenticator.
  def generate_otp_secret!
    update!(otp_secret: ROTP::Base32.random) unless otp_enabled?
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
  # only time the plaintext codes exist).
  def enable_two_factor!
    update!(otp_enabled: true, otp_enabled_at: Time.current)
    generate_backup_codes!
  end

  # Replace the backup codes with a fresh batch, returning the plaintext list
  # for one-time display. Digests (never the codes) are what gets stored.
  def generate_backup_codes!
    codes = Array.new(BACKUP_CODE_COUNT) { SecureRandom.hex(4) }
    update!(otp_backup_codes: codes.map { |c| BCrypt::Password.create(c).to_s }.to_json)
    codes
  end

  # Consume one backup code: returns true and removes it if it matches an
  # unused digest, false otherwise.
  def invalidate_backup_code!(code)
    return false if code.blank?

    normalized = code.to_s.strip
    digests = backup_code_digests
    match = digests.find { |digest| BCrypt::Password.new(digest) == normalized }
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
end
