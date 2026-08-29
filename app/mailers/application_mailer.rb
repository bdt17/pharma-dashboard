class ApplicationMailer < ActionMailer::Base
  # Same MAILER_SENDER env var Devise's mailer uses (config/initializers/devise.rb)
  # so there's one place to set the real sending address per environment.
  default from: ENV.fetch("MAILER_SENDER", "no-reply@pharmatransport.org")
  layout "mailer"
end
