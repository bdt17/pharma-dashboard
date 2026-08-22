class Batch < ApplicationRecord
  belongs_to :vehicle, optional: true
  belongs_to :driver, class_name: "User", inverse_of: :driven_batches, optional: true
  belongs_to :organization

  validates :lot_number, presence: true
  validates :temperature_celsius, numericality: { greater_than_or_equal_to: 2, less_than_or_equal_to: 8 }

  scope :compliant, -> { where(temperature_celsius: 2..8) }
  scope :active, -> { where(status: "active") }

  def compliance_status
    temperature_celsius.between?(2, 8) ? "compliant" : "non-compliant"
  end

  def self.to_csv
    require "csv"
    attributes = %w[id lot_number vehicle_id temperature_celsius status created_at]
    CSV.generate(headers: true) do |csv|
      all.each do |batch|
        csv << batch.attributes.values_at(*attributes)
      end
    end
  end
end
