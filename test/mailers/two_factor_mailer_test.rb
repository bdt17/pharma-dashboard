require "test_helper"

class TwoFactorMailerTest < ActionMailer::TestCase
  setup do
    @user = User.create!(
      email: "notify@example.com", password: "password123!",
      organization: Organization.create!(name: "Acme"), role: "admin"
    )
  end

  test "enabled mail is addressed to the user and names the account" do
    mail = TwoFactorMailer.with(user: @user).enabled

    assert_equal [ "notify@example.com" ], mail.to
    assert_equal "Two-factor authentication was turned on", mail.subject
    assert_match "notify@example.com", mail.body.encoded
    assert_match "backup codes", mail.body.encoded
  end

  test "disabled mail warns and mentions re-enrollment for a required role" do
    mail = TwoFactorMailer.with(user: @user).disabled

    assert_equal [ "notify@example.com" ], mail.to
    assert_equal "Two-factor authentication was turned off", mail.subject
    assert_match "no longer active", mail.body.encoded
    assert_match "set two-factor up again", mail.body.encoded
  end

  test "disabled mail to an opt-in role does not mention forced re-enrollment" do
    @user.update!(role: "dispatcher")

    mail = TwoFactorMailer.with(user: @user).disabled

    assert_no_match "set two-factor up again", mail.body.encoded
  end
end
