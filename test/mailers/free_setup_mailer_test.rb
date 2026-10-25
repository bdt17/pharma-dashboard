require "test_helper"

class FreeSetupMailerTest < ActionMailer::TestCase
  test "owed tells the operator who to call" do
    organization = Organization.create!(name: "Dana Pharmacy")
    User.create!(email: "dana@example.com", password: "password123!", organization: organization, role: "admin")

    mail = FreeSetupMailer.owed(organization)

    assert_equal "Free setup owed — Dana Pharmacy just subscribed", mail.subject
    assert_equal [ "dana@example.com" ], mail.reply_to
    assert_match "dana@example.com", mail.text_part.body.to_s
    assert_match "/ops#free-setups", mail.text_part.body.to_s
  end
end
