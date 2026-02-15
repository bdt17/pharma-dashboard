FactoryBot.define do
  factory :chain_of_custody_report do
    batch { nil }
    organization { nil }
    pdf_data { "" }
    status { "MyString" }
  end
end
