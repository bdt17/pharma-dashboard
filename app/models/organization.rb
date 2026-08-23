class Organization < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :vehicles, dependent: :restrict_with_error
  has_many :batches, dependent: :restrict_with_error
  has_many :subscriptions, dependent: :destroy
  has_many :compliance_reports, dependent: :restrict_with_error

  validates :name, presence: true
end
