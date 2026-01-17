class Batch < ApplicationRecord
  validates :lot, presence: true, uniqueness: true
end
