# One attempt to deliver one event envelope to one endpoint -- the row
# behind the delivery log and the "Re-send" button. Created by
# WebhookDispatcher (and WebhookEndpointsController#test) before the job
# runs; the job fills in the outcome. A manual replay is a fresh row with
# `replayed_from` pointing at the original.
class WebhookDelivery < ApplicationRecord
  belongs_to :webhook_endpoint
  belongs_to :replayed_from, class_name: "WebhookDelivery", optional: true
  has_many :replays, class_name: "WebhookDelivery", foreign_key: :replayed_from_id, dependent: :nullify, inverse_of: :replayed_from

  # Rows older than this are purged by the purge_old_webhook_deliveries
  # recurring task (see config/recurring.yml).
  RETENTION = 30.days

  enum :status, { pending: "pending", succeeded: "succeeded", failed: "failed" }, validate: true

  validates :event, :event_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :expired, -> { where(created_at: ...RETENTION.ago) }

  def replay?
    replayed_from_id.present?
  end
end
