# One row per public-form submission BotProtection turned away, so /ops can
# show whether the protection is actually catching anything. Kept apart
# from logs because Render's log retention is short and nothing else
# aggregates them; rows older than RETENTION are pruned as new ones arrive.
class BotBlock < ApplicationRecord
  RETENTION = 90.days

  def self.record!(form:, reason:)
    create!(form: form, reason: reason)
    where(created_at: ...RETENTION.ago).delete_all if rand < 0.01
  end
end
