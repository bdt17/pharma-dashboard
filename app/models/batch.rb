class Batch < ApplicationRecord
  belongs_to :vehicle
  include Auditable
  
  # DEA Compliance Fields
  attribute :ndc_code, :string
  attribute :lot_number, :string  
  attribute :expiry_date, :date
  attribute :signed_at, :datetime
  attribute :signed_by, :string
  attribute :dea_compliant, :boolean, default: false
  
  # Validations for DEA compliance
  validates :ndc_code, presence: true, if: :dea_controlled?
  validates :lot_number, presence: true
  validates :expiry_date, presence: true, if: :dea_controlled?
  
  # Chain of custody scope
  scope :audit_trail, -> { includes(audit_logs: :user).order(:created_at) }
  
  def dea_controlled?
    # Schedule II-V controlled substances
    %w[oxycodone fentanyl hydrocodone methadone].any? { |drug| name&.downcase&.include?(drug) }
  end
  
  def dea_compliant?
    dea_controlled? ? (signed_at.present? && audit_logs.pharmacist_sign.count >= 1) : true
  end
  
  def chain_of_custody_complete?
    audit_logs.count >= 3 && dea_compliant? # manufacture→ship→dispense
  end
  
  # Pharmacist digital signature
  def sign_custody!(pharmacist_name, pin)
    return false unless valid_pin?(pin)
    
    update!(
      signed_at: Time.current,
      signed_by: pharmacist_name,
      dea_compliant: true
    )
    
    audit_logs.create!(
      action: "pharmacist_sign",
      details: { pharmacist: pharmacist_name, pin_verified: true }
    )
  end
  
  private
  
  def valid_pin?(pin)
    pin == ENV['PHARMACIST_PIN'] # Set in Render dashboard
  end
end
