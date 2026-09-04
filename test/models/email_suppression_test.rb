require "test_helper"

class EmailSuppressionTest < ActiveSupport::TestCase
  test "suppressed? is false until suppress! is called, case- and whitespace-insensitively" do
    assert_not EmailSuppression.suppressed?("lead@example.com")

    EmailSuppression.suppress!("  Lead@Example.com  ")

    assert EmailSuppression.suppressed?("lead@example.com")
    assert EmailSuppression.suppressed?("LEAD@EXAMPLE.COM")
  end

  test "suppress! is idempotent -- calling it twice doesn't raise" do
    EmailSuppression.suppress!("lead@example.com")

    assert_nothing_raised { EmailSuppression.suppress!("lead@example.com") }
    assert_equal 1, EmailSuppression.where(email: "lead@example.com").count
  end
end
