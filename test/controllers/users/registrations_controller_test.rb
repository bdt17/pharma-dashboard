require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "signing up creates a new organization with the signer as its admin" do
    assert_difference [ "Organization.count", "User.count" ], 1 do
      post user_registration_path, params: {
        user: { organization_name: "Acme Pharma", email: "founder@example.com",
                password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
      }
    end

    user = User.find_by(email: "founder@example.com")
    assert_equal "Acme Pharma", user.organization.name
    assert user.admin?
  end

  test "a blank organization name is rejected with a real, readable error, not a generic one" do
    assert_no_difference [ "Organization.count", "User.count" ] do
      post user_registration_path, params: {
        user: { organization_name: "", email: "founder@example.com",
                password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
      }
    end

    assert_response :unprocessable_content
    assert_match "Organization name", response.body
  end

  test "signup without accepting the terms is rejected" do
    assert_no_difference [ "Organization.count", "User.count" ] do
      post user_registration_path, params: {
        user: { organization_name: "Acme Pharma", email: "founder@example.com",
                password: "password123!", password_confirmation: "password123!" }
      }
    end

    assert_response :unprocessable_content
    assert_match "must be accepted", response.body
  end

  test "a self-service signup is not confirmed and cannot sign in until they click the emailed link" do
    post user_registration_path, params: {
      user: { organization_name: "Acme Pharma", email: "founder@example.com",
              password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
    }

    user = User.find_by(email: "founder@example.com")
    assert_not user.confirmed?

    post user_session_path, params: { user: { email: user.email, password: "password123!" } }
    assert_redirected_to new_user_session_path

    user.confirm
    post user_session_path, params: { user: { email: user.email, password: "password123!" } }
    assert_redirected_to root_path
  end

  test "signing up with a valid referral code records a referral" do
    referrer = Organization.create!(name: "Referring Pharmacy", referral_code: "REFER123")

    assert_difference "Referral.count", 1 do
      post user_registration_path, params: {
        user: { organization_name: "New Pharmacy", email: "founder@example.com", referral_code: "refer123",
                password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
      }
    end

    referral = Referral.last
    assert_equal referrer, referral.referrer_organization
    assert_equal "New Pharmacy", referral.referred_organization.name
    assert_nil referral.rewarded_at
  end

  test "signing up with no referral code does not record a referral" do
    assert_no_difference "Referral.count" do
      post user_registration_path, params: {
        user: { organization_name: "New Pharmacy", email: "founder@example.com",
                password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
      }
    end
  end

  test "signing up with an unknown referral code does not fail signup or record a referral" do
    assert_difference "Organization.count", 1 do
      assert_no_difference "Referral.count" do
        post user_registration_path, params: {
          user: { organization_name: "New Pharmacy", email: "founder@example.com", referral_code: "NOPE0000",
                  password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
        }
      end
    end

    assert_response :redirect
  end

  test "a duplicate email is rejected" do
    Organization.create!(name: "Existing Org").users.create!(
      email: "taken@example.com", password: "password123!", role: "admin"
    )

    assert_no_difference [ "Organization.count", "User.count" ] do
      post user_registration_path, params: {
        user: { organization_name: "New Org", email: "taken@example.com",
                password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
      }
    end
  end
end
