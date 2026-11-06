require "test_helper"

# Every GET route, signed out: either it's on the public list below, or it
# sends the visitor to sign in (or answers 401/404). A new page that forgets
# authenticate_user! fails here instead of shipping open.
class RouteAuthSweepTest < ActionDispatch::IntegrationTest
  PUBLIC = %w[
    / /about /pricing /security /privacy /terms /dscsa-2026 /independent-pharmacy /compliance-officer
    /blog/small-pharmacy-dscsa-exemption-2026 /dscsa-assessment /dscsa-assessment/:token
    /dscsa-assessment/:token/report.pdf /request-a-call /request-a-call/thanks /unsubscribe
    /invitations/:token /verify/:token /verify/:token/badge.svg /health /up /login /signup /landing
    /subscribe /batches.pdf /users/sign_in /users/sign_up /users/password/new /users/password/edit
    /users/confirmation /users/confirmation/new /users/unlock /users/unlock/new /users/cancel
    /two_factor_challenge/new
  ].freeze

  def get_routes
    Rails.application.routes.routes.filter_map do |route|
      next unless route.verb.to_s.include?("GET")

      path = route.path.spec.to_s.sub("(.:format)", "")
      next if path.start_with?("/rails/", "/recede", "/resume", "/refresh", "/cable") || path.include?("*")

      path
    end.uniq
  end

  test "every non-public GET route requires sign-in" do
    checked = 0
    (get_routes - PUBLIC).each do |pattern|
      path = pattern.gsub(/:(\w+)/) { |m| m == ":token" ? "nope" : "1" }
      get path, headers: { "Accept" => "text/html" }
      ok = response.redirect? && response.location.include?("/users/sign_in")
      ok ||= response.status.in?([ 401, 404 ])
      assert ok, "#{pattern} answered #{response.status} to a signed-out visitor"
      checked += 1
    end
    assert_operator checked, :>, 25
  end

  test "the public list only names routes that exist" do
    stale = PUBLIC - get_routes - %w[/up]
    assert_empty stale, "remove these from PUBLIC: #{stale.join(', ')}"
  end
end

class SecurityTxtTest < ActionDispatch::IntegrationTest
  test "security.txt names a contact and an expiry in the future" do
    body = File.read(Rails.root.join("public/.well-known/security.txt"))
    assert_match(/^Contact: mailto:/, body)
    expires = Time.iso8601(body[/^Expires: (.+)$/, 1])
    assert expires > Time.current, "security.txt Expires has passed -- bump it"
  end
end
