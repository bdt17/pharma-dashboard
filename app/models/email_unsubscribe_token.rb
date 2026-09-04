# Signs and verifies the token behind /unsubscribe -- a tamper-proof
# encoding of an email address using the app's own secret_key_base (via
# Rails.application.message_verifier), not a value stored anywhere. One
# place for both DscsaAssessmentMailer (which generates the link) and
# UnsubscribesController (which verifies it) so the salt can't drift
# between the two.
class EmailUnsubscribeToken
  SALT = "email_unsubscribe"

  def self.generate(email)
    verifier.generate(email.to_s)
  end

  # nil on a missing, malformed, or tampered token, rather than raising --
  # a stale or hand-edited link should show "this link didn't work", not
  # a 500.
  def self.email_for(token)
    verifier.verify(token.to_s)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def self.verifier
    Rails.application.message_verifier(SALT)
  end
end
