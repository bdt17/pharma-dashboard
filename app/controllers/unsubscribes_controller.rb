# Unsubscribe from marketing-style email (currently the DSCSA assessment
# follow-up sequence -- see DscsaAssessmentMailer). `token` is a signed,
# tamper-proof encoding of the email address (see EmailUnsubscribeToken),
# not the raw address, so the link can't be replayed against a different
# address. Public, no account required.
#
# GET only shows a confirm button; the POST is what unsubscribes. Corporate
# link scanners and mail prefetchers follow GET links, and used to
# unsubscribe people who never clicked. Mail clients' own one-click button
# (List-Unsubscribe-Post, RFC 8058) POSTs here directly. The signed token is
# the authorization, so there's no CSRF token to check on that POST.
class UnsubscribesController < ApplicationController
  skip_forgery_protection only: :create

  def show
    @token = params[:token].to_s
    @email = EmailUnsubscribeToken.email_for(@token)
    @invalid = @email.nil?
  end

  def create
    @email = EmailUnsubscribeToken.email_for(params[:token])

    if @email
      EmailSuppression.suppress!(@email)
      @done = true
    else
      @invalid = true
    end
    render :show
  end
end
