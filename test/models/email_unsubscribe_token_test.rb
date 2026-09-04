require "test_helper"

class EmailUnsubscribeTokenTest < ActiveSupport::TestCase
  test "a generated token verifies back to the original email" do
    token = EmailUnsubscribeToken.generate("lead@example.com")

    assert_equal "lead@example.com", EmailUnsubscribeToken.email_for(token)
  end

  test "a tampered, malformed, or missing token returns nil rather than raising" do
    valid = EmailUnsubscribeToken.generate("lead@example.com")

    assert_nil EmailUnsubscribeToken.email_for("#{valid}tampered")
    assert_nil EmailUnsubscribeToken.email_for("not-a-real-token")
    assert_nil EmailUnsubscribeToken.email_for(nil)
  end
end
