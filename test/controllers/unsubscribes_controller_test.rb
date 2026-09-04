require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  test "a valid token suppresses the email and confirms it" do
    token = EmailUnsubscribeToken.generate("lead@example.com")

    get unsubscribe_url(token: token)

    assert_response :success
    assert EmailSuppression.suppressed?("lead@example.com")
    assert_match "lead@example.com", response.body
  end

  test "an invalid token shows an error instead of suppressing anything" do
    get unsubscribe_url(token: "garbage")

    assert_response :success
    assert_equal 0, EmailSuppression.count
    assert_match "That link didn", response.body
  end

  test "is idempotent -- following the same link twice doesn't error" do
    token = EmailUnsubscribeToken.generate("lead@example.com")

    get unsubscribe_url(token: token)
    get unsubscribe_url(token: token)

    assert_response :success
    assert_equal 1, EmailSuppression.count
  end
end
