# Invisible spam protection for the public forms (signup, request-a-call,
# the DSCSA assessment). Rack::Attack only limits request *rate*; the bot
# that filled production with random-letter call requests and dotted-Gmail
# signups submitted once every few days and never came close to a limit.
#
# Two checks, no CAPTCHA, nothing a real visitor sees:
#   1. Honeypot -- an off-screen field (see BotProtectionHelper) people never
#      see or tab into, but form-filling bots populate. Tripping it is
#      unambiguous, so the controller pretends the submission succeeded and
#      saves nothing: the bot gets no signal to adapt to.
#   2. Fill time -- a signed timestamp of when the form was rendered. A
#      submission faster than MIN_FILL_TIME, or with the timestamp missing,
#      forged, or older than MAX_FORM_AGE, is re-shown with a "please submit
#      again" notice instead of being dropped, so a person whose password
#      manager filled everything instantly only loses one click.
#
# A including controller calls `protect_from_bots only: :create` and defines
# #pretend_bot_submission_succeeded and #ask_to_resubmit_form.
module BotProtection
  extend ActiveSupport::Concern

  HONEYPOT_FIELD = :website_url
  TIMESTAMP_FIELD = :form_rendered_token
  MIN_FILL_TIME = 3.seconds
  MAX_FORM_AGE = 1.day
  RESUBMIT_NOTICE = "Sorry, we couldn't process that. Please check the form and submit it again.".freeze

  # Off in the test suite by default (like Rack::Attack) so every existing
  # form test doesn't need the extra fields; BotProtectionTest turns it on.
  mattr_accessor :enabled, default: !Rails.env.test?

  def self.verifier
    Rails.application.message_verifier(:bot_protection)
  end

  def self.form_token(now = Time.current)
    verifier.generate(now.to_f, purpose: :form_rendered, expires_at: now + MAX_FORM_AGE)
  end

  # nil for a plausible human submission, otherwise why it was flagged.
  def self.verdict(params, now: Time.current)
    return nil unless enabled
    return :honeypot if params[HONEYPOT_FIELD].present?

    rendered_at = verifier.verified(params[TIMESTAMP_FIELD].to_s, purpose: :form_rendered)
    return :missing_or_invalid_token unless rendered_at.is_a?(Numeric)
    return :too_fast if now.to_f - rendered_at < MIN_FILL_TIME
    # Checked here as well as by the token's own expiry, so the age limit
    # always runs from when the form was rendered.
    return :expired if now.to_f - rendered_at > MAX_FORM_AGE

    nil
  end

  class_methods do
    def protect_from_bots(**options)
      before_action :reject_likely_bots, **options
    end
  end

  private

  def reject_likely_bots
    verdict = BotProtection.verdict(params)
    return unless verdict

    Rails.logger.info("[BotProtection] blocked #{controller_path}##{action_name} (#{verdict}) from #{request.remote_ip}")
    verdict == :honeypot ? pretend_bot_submission_succeeded : ask_to_resubmit_form
  end
end
