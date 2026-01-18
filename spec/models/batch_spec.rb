require 'rails_helper'

RSpec.describe Batch, type: :model do
  describe 'FDA 21 CFR Part 11 compliance' do
    it 'flags temperature excursions >8°C or <2°C' do
      excursion_batch = Batch.new(temperature_celsius: 10.5)
      expect(excursion_batch.compliance_violation?).to be true
      expect(excursion_batch.compliance_status).to eq 'EXCURSION'
    end
    
    it 'approves compliant cold chain 2-8°C' do
      compliant_batch = Batch.new(temperature_celsius: 4.2)
      expect(compliant_batch.compliance_violation?).to be false
      expect(compliant_batch.compliance_status).to eq 'COMPLIANT'
    end
    
    it 'requires unique lot numbers' do
      Batch.create!(lot: 'LOT-PHARMA-20260117')
      duplicate = Batch.new(lot: 'LOT-PHARMA-20260117')
      expect(duplicate).not_to be_valid
    end
  end
end
