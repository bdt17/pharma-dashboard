# Day 1 / 3 / 7 nudges for a new organization that hasn't finished the
# Dashboard's "Getting started" checklist, plus a heads-up three days
# before a trial ends. Runs daily (config/recurring.yml).
#
# Each nudge points at the org's next unfinished step (OnboardingMailer),
# and the sequence stops for good once the org is fully_activated?. If the
# job misses a day, only the latest due nudge goes out -- never two at
# once. Orgs flagged internal, and admins who unsubscribed
# (EmailSuppression), get nothing. The trial notice is account mail, like
# the card-expiry notice, so it ignores suppression.
class OnboardingEmailJob < ApplicationJob
  queue_as :default

  SCHEDULE = [ 1.day, 3.days, 7.days ].freeze
  # Orgs older than this never start the sequence (e.g. accounts that
  # existed before it shipped).
  WINDOW = 10.days
  TRIAL_NOTICE_LEAD = 3.days

  def perform(now: Time.current)
    send_nudges(now)
    send_trial_notices(now)
  end

  private

  def send_nudges(now)
    Organization.customers.where(created_at: (now - WINDOW)..)
                .where(onboarding_emails_sent: ...SCHEDULE.size).find_each do |organization|
      next if organization.fully_activated?

      due = SCHEDULE.count { |offset| organization.created_at + offset <= now }
      next unless due > organization.onboarding_emails_sent

      admins(organization).reject { |user| EmailSuppression.suppressed?(user.email) }.each do |user|
        OnboardingMailer.nudge(user, due).deliver_later
      end
      organization.update!(onboarding_emails_sent: due)
    end
  end

  def send_trial_notices(now)
    Subscription.trialing.where(trial_ending_notified_at: nil, current_period_end: now..(now + TRIAL_NOTICE_LEAD))
                .joins(:organization).merge(Organization.customers).includes(:organization).find_each do |subscription|
      admins(subscription.organization).each do |user|
        OnboardingMailer.trial_ending(user, subscription).deliver_later
      end
      subscription.update!(trial_ending_notified_at: now)
    end
  end

  # Confirmed addresses only: never mail an address nobody has verified
  # (signups get 24 hours of unconfirmed access -- see devise.rb).
  def admins(organization)
    organization.users.active.where(role: "admin").where.not(confirmed_at: nil).to_a
  end
end
