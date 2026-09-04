# The app-wide replacement for ActionMailer::MailDeliveryJob (wired in via
# config.action_mailer.delivery_job in config/application.rb, so every
# `SomeMailer.foo.deliver_later` call in the app goes through this, not
# just one mailer that remembers to opt in).
#
# Why this exists: config/environments/production.rb sets
# raise_delivery_errors = false, on purpose -- see the comment there and
# User#send_devise_notification. But that flag is checked *inside*
# Mail::Message#deliver (do_delivery rescues the SMTP error and simply
# doesn't re-raise when the flag is false), which is called by the
# default MailDeliveryJob via `message.send("deliver_now")`. That means
# an SMTP failure during any background mail send -- auth rejected,
# connection timeout, whatever -- vanishes with zero trace: no
# exception, no SolidQueue::FailedExecution row, no log line, nothing.
# Confirmed empirically this session: a real test email never arrived,
# and the delivery job had recorded a clean, error-free finish.
# send_devise_notification already got its own explicit rescue+log for
# exactly this reason, but that only covers Devise's own synchronous
# mail (password reset, confirmation) -- every other mailer in this app
# (dunning, card-expiry, excursion alerts, the DSCSA follow-up sequence,
# call-request notifications, 2FA) goes through deliver_later, so none
# of them had any failure visibility at all.
#
# Fix: use deliver_now! (the bang version) instead of the plain
# deliver_now the default job calls -- deliver! has no internal rescue,
# so an SMTP failure actually reaches here as a real exception -- and
# rescue+log it ourselves, deliberately not re-raising. That keeps the
# same "a mail outage doesn't retry-storm or fail the job" intent
# raise_delivery_errors = false was set for, but makes it actually
# visible in the logs, which the flag alone never did.
#
# Only wraps the final send, not building the message: a template
# rendering bug or bad mailer-method call still raises normally and
# shows up as a real SolidQueue::FailedExecution, same as today -- it's
# specifically delivery failures (infrastructure, not code) that get
# swallowed-but-logged here.
class ApplicationMailDeliveryJob < ActionMailer::MailDeliveryJob
  def perform(mailer, mail_method, _delivery_method, args:, kwargs: nil, params: nil)
    mailer_class = params ? mailer.constantize.with(params) : mailer.constantize
    message = kwargs ? mailer_class.public_send(mail_method, *args, **kwargs) : mailer_class.public_send(mail_method, *args)

    begin
      message.deliver_now!
    rescue StandardError => e
      Rails.logger.error("[ApplicationMailDeliveryJob] #{mailer}##{mail_method} failed to send: #{e.class}: #{e.message}")
    end
  end
end
