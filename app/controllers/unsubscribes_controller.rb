# One-click unsubscribe from marketing-style email (currently the DSCSA
# assessment follow-up sequence -- see DscsaAssessmentMailer). `token` is
# a signed, tamper-proof encoding of the email address (see
# EmailUnsubscribeToken), not the raw address, so the link in an email
# body isn't just "?email=someone@example.com" for anyone to replay
# against a different address. Public, no account required -- the whole
# point is that it works from an email client with one click.
class UnsubscribesController < ApplicationController
  def show
    email = EmailUnsubscribeToken.email_for(params[:token])

    if email
      EmailSuppression.suppress!(email)
      @email = email
    else
      @invalid = true
    end
  end
end
