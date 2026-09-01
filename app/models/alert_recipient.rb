# A phone number that gets an SMS when one of the organization's shipments
# starts a temperature excursion. See ExcursionNotifier / SmsExcursionAlertJob.
class AlertRecipient < ApplicationRecord
  belongs_to :organization

  # E.164: a leading "+" and 8-15 digits, first digit non-zero. Stored
  # normalized (see #normalize_phone) so what's displayed is what Twilio
  # is handed.
  E164 = /\A\+[1-9]\d{7,14}\z/

  before_validation :normalize_phone

  validates :label, presence: true, length: { maximum: 60 }
  validates :phone, presence: true, format: { with: E164, message: "must be in international format, e.g. +14155550100" }
  validates :phone, uniqueness: { scope: :organization_id, message: "is already on the list" }

  scope :active, -> { where(active: true) }

  private

  # Accept the common ways someone types a US number -- "(415) 555-0100",
  # "415-555-0100", "4155550100" -- and turn them into +14155550100. A
  # value that already starts with "+" is only stripped of spaces and
  # punctuation; anything still not E.164 fails validation rather than
  # being silently mangled.
  def normalize_phone
    return if phone.blank?

    trimmed = phone.strip
    if trimmed.start_with?("+")
      self.phone = "+" + trimmed[1..].gsub(/\D/, "")
    else
      digits = trimmed.gsub(/\D/, "")
      self.phone = digits.length == 10 ? "+1#{digits}" : "+#{digits}"
    end
  end
end
