class Batch < ApplicationRecord
  validates :lot, presence: true, uniqueness: true
  def compliance_violation?
    temperature_celsius.nil? || temperature_celsius < 2.0 || temperature_celsius > 8.0
  end
  
  def compliance_status
    compliance_violation? ? 'EXCURSION' : 'COMPLIANT'
  end
end
