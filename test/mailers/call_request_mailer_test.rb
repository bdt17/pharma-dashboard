require "test_helper"

class CallRequestMailerTest < ActionMailer::TestCase
  test "notify goes to the leads address, replies to the requester, and includes the details" do
    cr = CallRequest.create!(
      name: "Dana Rx", email: "dana@example.com", pharmacy_name: "Dana Pharmacy",
      phone: "555-0100", topic: "compliance_officer", message: "We need help", context: "score 40/100"
    )

    mail = CallRequestMailer.notify(cr)

    assert_equal [ "dana@example.com" ], mail.reply_to
    assert_match "Fractional compliance officer", mail.subject
    assert_match "Dana Pharmacy", mail.subject
    body = mail.body.encoded
    assert_match "dana@example.com", body
    assert_match "555-0100", body
    assert_match "We need help", body
    assert_match "score 40/100", body
  end
end
