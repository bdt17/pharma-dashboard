# Two-factor authentication (TOTP), required for every user.
#
# How it fits together:
#   * User + app/models/concerns/two_factor_authentication.rb hold the secret,
#     the enabled flag, the backup codes, and the verify primitives.
#   * ApplicationController#enforce_two_factor is the gate: a signed-in user
#     who has not passed the second factor this session is redirected to
#     enrollment (TwoFactor::SetupController) or the challenge
#     (TwoFactor::ChallengeController).
#   * "Passed the second factor this session" is recorded as
#     warden.session(:user)["mfa_passed"], which Warden drops automatically on
#     logout.
#
# The hook below clears that marker on every fresh password authentication, so
# signing in again always re-triggers the challenge even in a browser that
# still has the cookie -- password alone is never enough to reach an
# authenticated page.
#
# Not covered here: the JSON API (namespace :api). Those endpoints are
# browser-session authenticated today and the gate only runs for HTML
# requests; token auth with its own second-factor story is a separate change.
#
# Follow-up: users.otp_secret is stored in plaintext because this app has no
# ActiveRecord encryption configured (no config/master.key). Wrap it in
# `encrypts :otp_secret` once credentials exist.
Warden::Manager.after_authentication do |_user, auth, opts|
  auth.session(opts[:scope]).delete("mfa_passed")
rescue StandardError
  nil
end
