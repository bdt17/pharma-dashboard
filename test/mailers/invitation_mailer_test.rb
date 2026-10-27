require "test_helper"

class InvitationMailerTest < ActionMailer::TestCase
  test "invite links the raw token, names the inviter and role, and replies to the inviter" do
    organization = Organization.create!(name: "Acme Pharma")
    admin = User.create!(email: "admin@example.com", name: "Pat Owner", password: "password123!", organization: organization, role: "admin")
    invitation = organization.invitations.create!(email: "new.driver@example.com", role: "driver", invited_by: admin)

    mail = InvitationMailer.invite(invitation, invitation.token)

    assert_equal [ "new.driver@example.com" ], mail.to
    assert_equal [ "admin@example.com" ], mail.reply_to
    assert_equal "Pat Owner invited you to Acme Pharma on Pharma Transport", mail.subject
    [ mail.html_part, mail.text_part ].each do |part|
      body = part.body.to_s
      assert_match "/invitations/#{invitation.token}", body
      assert_match "driver", body
      assert_no_match invitation.token_digest, body
    end
  end
end
