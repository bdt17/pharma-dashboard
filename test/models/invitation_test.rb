require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
  end

  def invite(email: "new.driver@example.com", role: "driver", organization: @organization)
    organization.invitations.create!(email: email, role: role, invited_by: @admin)
  end

  def accept(invitation, **overrides)
    invitation.accept!(**{ name: "Dana Driver", password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }.merge(overrides))
  end

  test "stores only a digest of the token, which finds it again" do
    invitation = invite
    assert_predicate invitation.token, :present?
    assert_not_equal invitation.token, invitation.token_digest
    assert_not_includes invitation.attributes.values.map(&:to_s), invitation.token
    assert_equal invitation, Invitation.find_pending_by_token(invitation.token)
    assert_nil Invitation.find_pending_by_token("not-a-token")
    assert_nil Invitation.find_pending_by_token(nil)
  end

  test "normalizes the email and expires in a week" do
    invitation = invite(email: "  New.Person@Example.COM ")
    assert_equal "new.person@example.com", invitation.email
    assert_in_delta 7.days.from_now, invitation.expires_at, 5.seconds
  end

  test "rejects an address that already has an account, anywhere" do
    other = Organization.create!(name: "Other Rx")
    User.create!(email: "taken@example.com", password: "password123!", organization: other)
    invitation = @organization.invitations.build(email: "Taken@example.com", role: "driver", invited_by: @admin)
    assert_not invitation.valid?
    assert_match "already has a Pharma Transport account", invitation.errors.full_messages.to_sentence
  end

  test "rejects a duplicate pending invite but allows one after revoking" do
    first = invite
    assert_not @organization.invitations.build(email: first.email, role: "driver", invited_by: @admin).valid?
    first.revoke!
    assert_predicate @organization.invitations.build(email: first.email, role: "driver", invited_by: @admin), :valid?
  end

  test "rejects an unknown role" do
    assert_not @organization.invitations.build(email: "x@example.com", role: "owner", invited_by: @admin).valid?
  end

  test "caps pending invitations per organization" do
    Invitation::MAX_PENDING.times { |i| invite(email: "person#{i}@example.com") }
    extra = @organization.invitations.build(email: "one.more@example.com", role: "driver", invited_by: @admin)
    assert_not extra.valid?
    assert_match "pending", extra.errors.full_messages.to_sentence
  end

  test "accepting creates a confirmed member of the inviting organization with the invited role" do
    invitation = invite(role: "pharmacist")
    member = accept(invitation)

    assert_predicate member, :persisted?
    assert_equal @organization, member.organization
    assert_equal "pharmacist", member.role
    assert_equal "new.driver@example.com", member.email
    assert_predicate member, :confirmed?
    assert_equal member, invitation.reload.user
    assert_not invitation.pending?
    assert_nil Invitation.find_pending_by_token(invitation.token)
  end

  test "an invitation works only once" do
    invitation = invite
    accept(invitation)
    again = accept(invitation, name: "Someone Else")
    assert_not again.persisted?
    assert_equal 2, @organization.users.count
  end

  test "expired and revoked invitations can't be accepted or found" do
    expired = invite(email: "late@example.com")
    expired.update_column(:expires_at, 1.minute.ago)
    assert_nil Invitation.find_pending_by_token(expired.token)
    assert_not accept(expired).persisted?

    revoked = invite(email: "gone@example.com")
    revoked.revoke!
    assert_not accept(revoked).persisted?
  end

  test "requires the terms and a valid password, without using up the invitation" do
    invitation = invite
    no_terms = accept(invitation, terms_accepted: "0")
    assert_not no_terms.persisted?
    assert_match "Terms", no_terms.errors.full_messages.to_sentence

    short = accept(invitation, password: "short", password_confirmation: "short")
    assert_not short.persisted?
    assert_predicate invitation.reload, :pending?
  end

  test "resending replaces the token, so the old link stops working" do
    invitation = invite
    old_token = invitation.token
    invitation.update_column(:expires_at, 1.day.from_now)
    invitation.regenerate_token!

    assert_nil Invitation.find_pending_by_token(old_token)
    assert_equal invitation, Invitation.find_pending_by_token(invitation.token)
    assert_in_delta 7.days.from_now, invitation.expires_at, 5.seconds
  end
end
