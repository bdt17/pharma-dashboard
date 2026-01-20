class Order < ApplicationRecord
  belongs_to :pharmacy
  belongs_to :patient
end
