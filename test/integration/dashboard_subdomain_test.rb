require "test_helper"

# `dashboard.pharmatransport.org` is a Render custom domain that only exists
# as a memorable shortcut. Every request on it 301s to the canonical host.
class DashboardSubdomainTest < ActionDispatch::IntegrationTest
  CANONICAL = ENV.fetch("APP_HOST", "pharmatransport.org")

  test "the bare dashboard subdomain redirects to the canonical dashboard" do
    get "http://dashboard.pharmatransport.org/"
    assert_response :moved_permanently
    assert_equal "https://#{CANONICAL}/dashboard", response.location
  end

  test "a deeper path keeps its path and query on the canonical host" do
    get "http://dashboard.pharmatransport.org/billing?ref=email"
    assert_redirected_to "https://#{CANONICAL}/billing?ref=email"
  end

  test "the canonical host is not redirected" do
    get "http://pharmatransport.org/"
    assert_response :success
  end

  test "an unrelated subdomain is not redirected" do
    get "http://www.pharmatransport.org/"
    assert_response :success
  end
end
