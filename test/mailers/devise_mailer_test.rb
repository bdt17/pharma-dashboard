require "test_helper"

# The account emails (Devise) are the first thing a new pharmacy receives,
# so they get the branded layout and plain wording, not Devise's defaults.
class DeviseMailerTest < ActionMailer::TestCase
  setup do
    organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "owner@example.com", name: "Pat Owner", password: "password123!", organization: organization, role: "admin")
  end

  test "confirmation email is branded and links to the confirmation" do
    mail = Devise::Mailer.confirmation_instructions(@user, "tok123")
    assert_equal "Confirm your Pharma Transport email", mail.subject
    html = mail.html_part.body.to_s
    assert_includes html, "Confirm my email"
    assert_includes html, "confirmation_token=tok123"
    assert_includes html, "Reply to this email"
    assert_not_includes html, "You can confirm your account email through the link below"
    assert_includes mail.text_part.body.to_s, "confirmation_token=tok123"
  end

  test "password reset email is branded, says when it expires, and links to the reset" do
    mail = Devise::Mailer.reset_password_instructions(@user, "tok456")
    assert_equal "Reset your Pharma Transport password", mail.subject
    html = mail.html_part.body.to_s
    assert_includes html, "Choose a new password"
    assert_includes html, "reset_password_token=tok456"
    assert_includes html, "6 hours"
    assert_not_includes html, "Someone has requested a link"
    assert_includes mail.text_part.body.to_s, "reset_password_token=tok456"
  end

  test "unlock email states the attempt count and auto-unlock time" do
    mail = Devise::Mailer.unlock_instructions(@user, "tok789")
    assert_equal "Unlock your Pharma Transport account", mail.subject
    assert_includes mail.html_part.body.to_s, "unlock_token=tok789"
    assert_includes mail.html_part.body.to_s, "1 hour"
  end

  test "email-changed and password-changed notices render" do
    assert_equal "Your Pharma Transport email is changing", Devise::Mailer.email_changed(@user).subject
    assert_includes Devise::Mailer.password_change(@user).html_part.body.to_s, "was just changed"
  end
end
