class ApplicationMailer < ActionMailer::Base
  # Same MAILER_SENDER env var Devise's mailer uses (config/initializers/devise.rb)
  # so there's one place to set the real sending address per environment.
  default from: ENV.fetch("MAILER_SENDER", "no-reply@pharmatransport.org")
  layout "mailer"

  private

  # Also sets the RFC 8058 one-click headers, so mail clients show their
  # own "Unsubscribe" button (Gmail/Yahoo bulk-sender requirement) that
  # POSTs straight to /unsubscribe.
  def unsubscribe_url_for(email)
    url = unsubscribe_url(token: EmailUnsubscribeToken.generate(email))
    headers["List-Unsubscribe"] = "<#{url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    url
  end
end
