require "test_helper"

class AccountUnlockTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "dispatch@example.com", password: "password123!", organization: organization, role: "dispatcher")
  end

  def fail_login
    post user_session_url, params: { user: { email: @user.email, password: "wrong-password" } }
  end

  test "a lock emails an unlock link that works before the hour is up" do
    perform_enqueued_jobs do
      Devise.maximum_attempts.times { fail_login }
    end
    assert_predicate @user.reload, :access_locked?

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ @user.email ], mail.to
    link = mail.body.encoded[%r{http://[^"\s]+/users/unlock\?unlock_token=[^"\s]+}]
    assert link, "unlock email has no unlock link"

    get link
    assert_not @user.reload.access_locked?

    post user_session_url, params: { user: { email: @user.email, password: "password123!" } }
    get dashboard_url
    assert_response :success
  end

  test "the lock still lifts on its own after unlock_in" do
    Devise.maximum_attempts.times { fail_login }
    assert_predicate @user.reload, :access_locked?

    travel Devise.unlock_in + 1.minute do
      assert_not @user.reload.access_locked?
    end
  end
end
