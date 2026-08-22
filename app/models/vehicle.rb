class Vehicle < ApplicationRecord
  belongs_to :organization
  has_many :batches
end
