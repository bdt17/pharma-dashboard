FactoryBot.define do
  factory :subscription do
    organization { nil }
    stripe_subscription_id { "MyString" }
    status { "MyString" }
    current_period_end { "2026-02-07 18:03:00" }
    plan_amount { "9.99" }
  end
end
