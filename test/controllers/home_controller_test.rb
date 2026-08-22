require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "home page renders successfully for a signed-out visitor" do
    get root_url
    assert_response :success
  end

  test "home page redirects a signed-in user straight to the dashboard" do
    organization = Organization.create!(name: "Acme Pharma")
    user = User.create!(email: "dispatcher@example.com", password: "password123!", organization: organization, role: "dispatcher")

    sign_in user
    get root_url

    assert_redirected_to dashboard_url
  end

  test "health endpoint responds successfully" do
    get health_url
    assert_response :success
  end

  test "gps requires authentication" do
    get gps_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "gps shows only the signed-in user's organization's vehicles" do
    org_a = Organization.create!(name: "Org A")
    org_b = Organization.create!(name: "Org B")
    user = User.create!(email: "dispatcher@example.com", password: "password123!", organization: org_a, role: "dispatcher")
    Vehicle.create!(name: "Visible Truck", organization: org_a)
    Vehicle.create!(name: "Hidden Truck", organization: org_b)

    sign_in user
    get gps_url

    assert_response :success
    assert_select "td", text: "Visible Truck"
    assert_select "td", text: "Hidden Truck", count: 0
  end
end
