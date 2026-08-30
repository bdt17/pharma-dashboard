require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(role: "admin")
    organization = Organization.create!(name: "Acme Pharma")
    User.new(
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123!",
      organization: organization,
      role: role
    )
  end

  test "requires an organization" do
    user = build_user
    user.organization = nil
    assert_not user.valid?
    assert_includes user.errors[:organization], "must exist"
  end

  test "defaults to the dispatcher role" do
    organization = Organization.create!(name: "Acme Pharma")
    user = User.new(email: "default@example.com", password: "password123!", organization: organization)
    assert_equal "dispatcher", user.role
  end

  test "a directly-created user is auto-confirmed (console / rake / seeds), unlike a signup" do
    # The accounts:create rake task and db/seeds rely on this: only the
    # public signup form (Users::RegistrationsController) flags
    # requires_email_confirmation, so a user built any other way is usable
    # immediately without a mail provider.
    user = build_user
    user.save!
    assert user.confirmed?

    signup = build_user
    signup.requires_email_confirmation = true
    signup.terms_accepted = true
    signup.save!
    assert_not signup.confirmed?
  end

  test "accepts each defined role" do
    %w[admin dispatcher driver pharmacist].each do |role|
      user = build_user(role: role)
      assert user.valid?, "expected role #{role} to be valid: #{user.errors.full_messages}"
    end
  end

  test "rejects a role outside the defined set" do
    # enum ... validate: true means an out-of-range value is a normal
    # validation error (shows up in errors, safe to rescue in a form), not a
    # hard ArgumentError crash.
    user = build_user(role: "superuser")
    assert_not user.valid?
    assert_includes user.errors[:role], "is not included in the list"
  end

  test "supports Devise lockable access-lock/unlock" do
    user = build_user
    user.save!
    assert_not user.access_locked?

    user.lock_access!
    assert user.access_locked?

    user.unlock_access!
    assert_not user.access_locked?
  end
end
