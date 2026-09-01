# Sends the follow-up payment-recovery emails. Runs daily (see
# config/recurring.yml). The first email in a sequence goes out
# immediately from the webhook (Subscription#handle_dunning_after_sync!);
# this job walks every still-failing subscription and sends the next one
# once Subscription::DUNNING_INTERVAL has passed, up to DUNNING_MAX_EMAILS.
class DunningSweepJob < ApplicationJob
  queue_as :default

  def perform
    Subscription.where(status: %w[past_due unpaid]).find_each do |subscription|
      subscription.send_dunning_email! if subscription.dunning_email_due?
    end
  end
end
