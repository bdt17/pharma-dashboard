require "test_helper"

class VerificationsControllerTest < ActionDispatch::IntegrationTest
  test "shows a verified badge for an organization with an active subscription" do
    org = Organization.create!(name: "Acme Pharma")
    Subscription.create!(organization: org, status: "active", stripe_subscription_id: "sub_123")

    get verification_url(org.verification_token)

    assert_response :success
    assert_match "DSCSA Compliance Verified", response.body
    assert_match "Acme Pharma", response.body
  end

  test "shows a not-verified state for an organization with no active subscription" do
    org = Organization.create!(name: "Acme Pharma")

    get verification_url(org.verification_token)

    assert_response :success
    assert_match "Not currently verified", response.body
  end

  test "does not require authentication" do
    org = Organization.create!(name: "Acme Pharma")

    get verification_url(org.verification_token)

    assert_response :success
  end

  test "returns 404 for an unknown token instead of raising" do
    get verification_url("no-such-token")

    assert_response :not_found
  end

  test "serves the badge as a cacheable SVG" do
    org = Organization.create!(name: "Acme Pharma")
    Subscription.create!(organization: org, status: "active", stripe_subscription_id: "sub_123")

    get verification_badge_url(org.verification_token)

    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_match "<svg", response.body
    assert_match "DSCSA verified", response.body
    assert_match(/max-age=3600/, response.headers["Cache-Control"])
  end

  test "the badge reflects an unverified organization" do
    org = Organization.create!(name: "Acme Pharma")

    get verification_badge_url(org.verification_token)

    assert_response :success
    assert_match "not verified", response.body
  end

  test "the badge is 404 for an unknown token, not a 500" do
    get verification_badge_url("no-such-token")
    assert_response :not_found
  end

  test "does not require authentication for the badge" do
    org = Organization.create!(name: "Acme Pharma")
    get verification_badge_url(org.verification_token)
    assert_response :success
  end
end
