class ChainOfCustodyReport < ApplicationRecord
  belongs_to :batch
  belongs_to :organization
end
