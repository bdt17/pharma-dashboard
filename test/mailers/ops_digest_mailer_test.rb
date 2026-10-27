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
        assert_match "59 days left", body
        assert_match "/ops", body
      end
    end
  end

  test "weekly drops the free setup line once the offer ends" do
    travel_to Time.utc(2027, 1, 4, 15) do
      body = OpsDigestMailer.weekly.text_part.body.to_s
      assert_no_match "Free setup offer", body
      assert_match "DSCSA small-dispenser deadline: November 27, 2027", body
    end
  end
end
