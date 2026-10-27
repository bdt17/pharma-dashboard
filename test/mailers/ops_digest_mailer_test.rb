require "test_helper"

class OpsDigestMailerTest < ActionMailer::TestCase
  test "weekly lists the week's leads and what's waiting, in both parts" do
    travel_to Time.utc(2026, 11, 2, 15) do
      CallRequest.create!(name: "Ana", pharmacy_name: "Ana's Pharmacy", email: "ana@example.com", topic: "general")
      Organization.create!(name: "Main Street Rx", free_setup_owed_at: 1.day.ago)

      mail = OpsDigestMailer.weekly

      assert_equal "Pharma Transport weekly — 1 lead, 0 new subscriptions, 1 setup owed", mail.subject
      [ mail.text_part, mail.html_part ].each do |part|
        body = part.body.to_s
        assert_match "Ana", body
        assert_match "ana@example.com", body
        assert_match "Main Street Rx", body
        assert_match "25 days left", body
        assert_match "/ops", body
      end
    end
  end

  test "weekly drops the deadline line after the deadline" do
    travel_to Time.utc(2026, 12, 7, 15) do
      assert_no_match "DSCSA deadline", OpsDigestMailer.weekly.text_part.body.to_s
    end
  end
end
