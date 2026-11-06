require "test_helper"

class UserTestEmailDomainTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "Acme")
  end

  def user(email) = User.create!(email: email, password: "password123!", organization: @org, role: "dispatcher")

  def with_blocking(value)
    original = Rails.configuration.x.block_test_email_sign_in
    Rails.configuration.x.block_test_email_sign_in = value
    yield
  ensure
    Rails.configuration.x.block_test_email_sign_in = original
  end

  test "recognises reserved and throwaway domains, including subdomains" do
    assert user("admin@example.com").test_email_address?
    assert user("a+1@mailinator.com").test_email_address?
    assert user("test+billing@yourdomain.com").test_email_address?
    assert user("x@srv1.mail-tester.com").test_email_address?
    assert_not user("brett@pharmatransport.org").test_email_address?
    assert_not user("someone@notexample.com").test_email_address?
  end

  test "production refuses sign-in for them, with its own message" do
    with_blocking(true) do
      blocked = user("pharma-monetize-check3@mailinator.com")
      assert_not blocked.active_for_authentication?
      assert_equal :test_address, blocked.inactive_message
      assert user("owner@mainstreetrx.com").active_for_authentication?
    end
  end

  test "dev and test still allow them" do
    with_blocking(false) { assert user("admin@example.com").active_for_authentication? }
  end

  test "production turns the block on" do
    prod = File.read(Rails.root.join("config/environments/production.rb"))
    assert_match(/config\.x\.block_test_email_sign_in = true/, prod)
  end
end
