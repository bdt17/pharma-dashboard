require "test_helper"

class UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  test "following the link only asks to confirm -- a link scanner's GET suppresses nothing" do
    token = EmailUnsubscribeToken.generate("lead@example.com")

    get unsubscribe_url(token: token)

    assert_response :success
    assert_not EmailSuppression.suppressed?("lead@example.com")
    assert_select "form[action=?][method=post]", unsubscribe_path(token: token)
  end

  test "confirming suppresses the email" do
    token = EmailUnsubscribeToken.generate("lead@example.com")

    post unsubscribe_url(token: token)

    assert_response :success
    assert EmailSuppression.suppressed?("lead@example.com")
    assert_match "unsubscribed", response.body
  end

  test "a mail client's one-click POST works without a CSRF token" do
    ActionController::Base.allow_forgery_protection = true
    token = EmailUnsubscribeToken.generate("lead@example.com")

    post unsubscribe_url(token: token), params: { "List-Unsubscribe" => "One-Click" }

    assert_response :success
    assert EmailSuppression.suppressed?("lead@example.com")
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "an invalid token shows an error instead of suppressing anything" do
    get unsubscribe_url(token: "garbage")
    assert_match "That link didn", response.body

    post unsubscribe_url(token: "garbage")
    assert_equal 0, EmailSuppression.count
    assert_match "That link didn", response.body
  end

  test "is idempotent -- confirming twice doesn't error" do
    token = EmailUnsubscribeToken.generate("lead@example.com")

    post unsubscribe_url(token: token)
    post unsubscribe_url(token: token)

    assert_response :success
    assert_equal 1, EmailSuppression.count
  end
end
