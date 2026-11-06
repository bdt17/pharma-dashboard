class AddOnboardingTracking < ActiveRecord::Migration[8.1]
  def change
    # How many of OnboardingEmailJob::SCHEDULE have gone out (0-3).
    add_column :organizations, :onboarding_emails_sent, :integer, default: 0, null: false
    add_column :subscriptions, :trial_ending_notified_at, :datetime
  end
end
