# pharmatransport.org is served through Cloudflare, which sits in front of
# Render's own proxy. Rails only trusts private-network proxies by default,
# so request.remote_ip resolved to a Cloudflare edge address instead of the
# visitor -- every Rack::Attack throttle was shared by everyone routed
# through the same edge, and custody logs / audit entries recorded
# Cloudflare's IP rather than the person's.
#
# Trusting Cloudflare's published ranges lets ActionDispatch::RemoteIp walk
# past them in X-Forwarded-For to the real client. Not spoofable: a client
# can prepend anything to X-Forwarded-For, but resolution reads from the
# right and stops at the first address that isn't a trusted proxy, which is
# always the hop Cloudflare (or Render, for a direct-to-origin request)
# actually saw. Source: https://www.cloudflare.com/ips/ -- the list changes
# rarely; refresh it from there if Cloudflare announces new ranges.
CLOUDFLARE_IP_RANGES = %w[
  173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22
  141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20
  197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13
  104.24.0.0/14 172.64.0.0/13 131.0.72.0/22
  2400:cb00::/32 2606:4700::/32 2803:f800::/32 2405:b500::/32
  2405:8100::/32 2a06:98c0::/29 2c0f:f248::/32
].map { |cidr| IPAddr.new(cidr) }.freeze

Rails.application.config.action_dispatch.trusted_proxies =
  ActionDispatch::RemoteIp::TRUSTED_PROXIES + CLOUDFLARE_IP_RANGES
