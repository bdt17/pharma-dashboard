require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "pages send a Content-Security-Policy with a script nonce, and a Permissions-Policy" do
    get root_path

    csp = response.headers["Content-Security-Policy"]
    assert_match "default-src 'self'", csp
    assert_match "object-src 'none'", csp
    assert_match(/script-src 'self'[^;]*'nonce-[^']+'/, csp)
    assert_match "form-action 'self' https://checkout.stripe.com https://billing.stripe.com", csp
    assert_select "meta[name=csp-nonce]"

    assert_match "camera=()", response.headers["Permissions-Policy"]
  end

  test "the importmap script carries the same nonce as the header" do
    get root_path

    nonce = response.headers["Content-Security-Policy"][/'nonce-([^']+)'/, 1]
    assert_select "script[type=importmap][nonce=?]", nonce
  end

  test "no inline event handlers anywhere in the views (CSP would block them)" do
    offenders = Dir[Rails.root.join("app/views/**/*.erb")].select { |f| File.read(f).match?(/\son[a-z]+="/) }
    assert_empty offenders.map { |f| f.delete_prefix("#{Rails.root}/") }
  end
end

# The visitor's real address, not Cloudflare's, is what rate limits and the
# audit trail see.
class CloudflareClientIpTest < ActionDispatch::IntegrationTest
  CLIENT = "203.0.113.7".freeze
  CLOUDFLARE_EDGE = "172.70.1.1".freeze # inside 172.64.0.0/13

  def resolved_ip_for(headers)
    ip = nil
    probe = ->(env) { ip = ActionDispatch::Request.new(env).remote_ip; [ 200, {}, [ "" ] ] }
    remote_ip = ActionDispatch::RemoteIp.new(probe, true, Rails.application.config.action_dispatch.trusted_proxies)
    remote_ip.call(Rack::MockRequest.env_for("/", { "REMOTE_ADDR" => "10.0.0.5" }.merge(headers)))
    ip
  end

  test "walks past the Cloudflare edge to the real client" do
    assert_equal CLIENT, resolved_ip_for("HTTP_X_FORWARDED_FOR" => "#{CLIENT}, #{CLOUDFLARE_EDGE}")
  end

  test "a forged X-Forwarded-For entry can't override the address Cloudflare saw" do
    assert_equal CLIENT, resolved_ip_for("HTTP_X_FORWARDED_FOR" => "1.2.3.4, #{CLIENT}, #{CLOUDFLARE_EDGE}")
  end

  test "a direct-to-origin request can't impersonate Cloudflare to pick its own address" do
    attacker = "198.51.100.9"
    assert_equal attacker, resolved_ip_for("HTTP_X_FORWARDED_FOR" => "1.2.3.4, #{CLOUDFLARE_EDGE}, #{attacker}")
  end

  test "Rack::Attack throttles on the resolved client address" do
    env = Rack::MockRequest.env_for("/", "REMOTE_ADDR" => "10.0.0.5", "action_dispatch.remote_ip" => CLIENT)
    assert_equal CLIENT, Rack::Attack::Request.new(env).ip
  end
end
