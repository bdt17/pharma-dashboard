# An inbound "have someone call me" lead from the public marketing pages.
# Not attached to a user or organization -- these come from people without
# an account. CallRequestMailer notifies the founder; handled_at is set
# by hand once it's been followed up.
class CallRequest < ApplicationRecord
  TOPICS = %w[compliance_officer compliance_officer_waitlist dscsa_assessment enterprise general].freeze

  TOPIC_LABELS = {
    "compliance_officer" => "Fractional compliance officer",
    "compliance_officer_waitlist" => "Compliance officer waitlist",
    "dscsa_assessment" => "DSCSA readiness check",
    "enterprise" => "Enterprise plan",
    "general" => "General enquiry"
  }.freeze

  validates :name, presence: true, length: { maximum: 200 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 300 }
  validates :pharmacy_name, :phone, length: { maximum: 200 }
  validates :message, length: { maximum: 4000 }
  validates :context, length: { maximum: 4000 }
  validates :topic, inclusion: { in: TOPICS }

  scope :unhandled, -> { where(handled_at: nil) }

  def topic_label
    TOPIC_LABELS.fetch(topic, topic.to_s.humanize)
  end
end
