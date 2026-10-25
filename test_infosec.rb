#!/usr/bin/env ruby
# Live security-header check against production: `ruby test_infosec.rb`
# (or pass another base URL). Every line is an actual check; it exits
# non-zero if any required header is missing or wrong.
require "net/http"

base = URI(ARGV[0] || "https://pharmatransport.org")
failures = 0
check = lambda do |label, ok, detail|
  puts "#{ok ? 'PASS' : 'FAIL'}  #{label.ljust(26)} #{detail}"
  failures += 1 unless ok
end

res = Net::HTTP.get_response(URI.join(base.to_s, "/users/sign_in"))
h = res.each_header.to_h

check.("HTTPS", base.scheme == "https", base.to_s)
check.("HSTS", h["strict-transport-security"].to_s.match?(/max-age=\d{7,}/), h["strict-transport-security"].inspect)
csp = h["content-security-policy"].to_s
check.("CSP present", !csp.empty?, csp.empty? ? "missing" : "#{csp.size} chars")
check.("CSP script nonce", csp.match?(/script-src [^;]*'nonce-/), "")
check.("CSP object-src none", csp.include?("object-src 'none'"), "")
check.("CSP no unsafe-inline JS", !csp[/script-src [^;]*/].to_s.include?("unsafe-inline"), "")
check.("Permissions-Policy", h["permissions-policy"].to_s.include?("camera=()"), h["permissions-policy"].inspect)
check.("X-Frame-Options", %w[DENY SAMEORIGIN].include?(h["x-frame-options"]), h["x-frame-options"].inspect)
check.("X-Content-Type-Options", h["x-content-type-options"] == "nosniff", h["x-content-type-options"].inspect)
check.("Referrer-Policy", h["referrer-policy"].to_s.start_with?("strict-origin"), h["referrer-policy"].inspect)
cookie = h["set-cookie"].to_s
check.("Session cookie flags", %w[secure httponly samesite].all? { |f| cookie.downcase.include?(f) }, "")

plain = Net::HTTP.get_response(URI("http://#{base.host}/"))
check.("HTTP -> HTTPS redirect", plain.is_a?(Net::HTTPRedirection) && plain["location"].to_s.start_with?("https://"), plain.code)

puts failures.zero? ? "\nAll checks passed." : "\n#{failures} check(s) failed."
exit(failures.zero? ? 0 : 1)
