require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "signing up creates a new organization with the signer as its admin" do
    assert_difference [ "Organization.count", "User.count" ], 1 do
      post user_registration_path, params: {
        user: { organization_name: "Acme Pharma", email: "founder@example.com",
                password: "password123!", password_confirmation: "password123!" }
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
                password: "password123!", password_confirmation: "password123!" }
      }
    end

    assert_response :unprocessable_content
    assert_match "Organization name", response.body
  end

  test "a self-service signup is not confirmed and cannot sign in until they click the emailed link" do
    post user_registration_path, params: {
      user: { organization_name: "Acme Pharma", email: "founder@example.com",
              password: "password123!", password_confirmation: "password123!" }
    }

    user = User.find_by(email: "founder@example.com")
    assert_not user.confirmed?

    post user_session_path, params: { user: { email: user.email, password: "password123!" } }
    assert_redirected_to new_user_session_path

    user.confirm
    post user_session_path, params: { user: { email: user.email, password: "password123!" } }
    assert_redirected_to root_path
  end

  test "a duplicate email is rejected" do
    Organization.create!(name: "Existing Org").users.create!(
      email: "taken@example.com", password: "password123!", role: "admin"
    )

    assert_no_difference [ "Organization.count", "User.count" ] do
      post user_registration_path, params: {
        user: { organization_name: "New Org", email: "taken@example.com",
                password: "password123!", password_confirmation: "password123!" }
      }
    end
  end
end
