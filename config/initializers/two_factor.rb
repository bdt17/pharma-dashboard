# Two-factor authentication (TOTP): mandatory for admins and pharmacists,
# opt-in for dispatchers and drivers.
#
# How it fits together:
#   * User + app/models/concerns/two_factor_authentication.rb hold the secret,
#     the enabled flag, the backup codes, the verify primitives, and
#     two_factor_required? (the role check).
#   * ApplicationController#enforce_two_factor is the gate: an enrolled user
#     who has not passed the second factor this session is sent to the
#     challenge (TwoFactor::ChallengeController); a required-role user who
#     hasn't enrolled is sent to setup (TwoFactor::SetupController). Everyone
#     else passes straight through.
#   * "Passed the second factor this session" is recorded as
#     warden.session(:user)["mfa_passed"], which Warden drops automatically on
#     logout.
#
# The hook below clears that marker on every fresh password authentication, so
# an enrolled user signing in again always re-triggers the challenge even in a
# browser that still has the cookie -- password alone is never enough.
#
# The session-authenticated JSON API (namespace :api) goes through the same
# gate: a non-HTML request that hasn't passed the second factor gets a 401
# rather than a redirect. Device-token endpoints (GPS ingest) don't use the
# user session and skip it.
#
# users.otp_secret is encrypted at rest (`encrypts :otp_secret` in the
# concern).
Warden::Manager.after_authentication do |_user, auth, opts|
  auth.session(opts[:scope]).delete("mfa_passed")
rescue StandardError
  nil
end
