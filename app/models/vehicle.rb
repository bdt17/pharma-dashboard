class Vehicle < ApplicationRecord
  has_many :location_points, dependent: :destroy
end
