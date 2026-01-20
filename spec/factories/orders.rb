FactoryBot.define do
  factory :order do
    pharmacy { nil }
    patient { nil }
    status { "MyString" }
    tracking_id { "MyString" }
  end
end
