#!/usr/bin/env ruby
# Live security check against production: `ruby test_infosec.rb`
# (or pass another base URL). Read-only and light -- about 80 requests, no
# logins, no form posts that change anything, nothing that could trip a
# lockout. Exits non-zero if any FAIL; WARN lines are worth a look but
# aren't regressions (mostly DNS and account settings outside the code).
require "net/http"
require "openssl"
require "resolv"
require "socket"

base = URI(ARGV[0] || "https://pharmatransport.org")
host = base.host
failures = 0
warnings = 0
check = lambda do |label, ok, detail = ""|
  puts "#{ok ? 'PASS' : 'FAIL'}  #{label.ljust(34)} #{detail}"
  failures += 1 unless ok
end
warn_check = lambda do |label, ok, detail = ""|
  puts "#{ok ? 'PASS' : 'WARN'}  #{label.ljust(34)} #{detail}"
  warnings += 1 unless ok
end
section = ->(name) { puts "\n== #{name}" }

http = Net::HTTP.new(host, base.port)
http.use_ssl = base.scheme == "https"
http.open_timeout = http.read_timeout = 15
http.start
request = lambda do |verb, path, headers = {}, body = nil|
  req = Net::HTTPGenericRequest.new(verb.to_s.upcase, !body.nil?, verb != :head, path, headers)
  req.body = body if body
  http.request(req)
end
redirects_to_login = ->(res) { res.is_a?(Net::HTTPRedirection) && res["location"].to_s.include?("/users/sign_in") }

# ---------------------------------------------------------------- headers
section.("Security headers (/users/sign_in)")
res = request.(:get, "/users/sign_in")
h = res.each_header.to_h
check.("HTTPS", base.scheme == "https", base.to_s)
check.("HSTS", h["strict-transport-security"].to_s.match?(/max-age=\d{7,}/), h["strict-transport-security"].inspect)
warn_check.("HSTS includeSubDomains", h["strict-transport-security"].to_s.include?("includeSubDomains"), "")
csp = h["content-security-policy"].to_s
check.("CSP present", !csp.empty?, csp.empty? ? "missing" : "#{csp.size} chars")
check.("CSP script nonce", csp.match?(/script-src [^;]*'nonce-/))
check.("CSP object-src none", csp.include?("object-src 'none'"))
check.("CSP no unsafe-inline JS", !csp[/script-src [^;]*/].to_s.include?("unsafe-inline"))
check.("CSP no unsafe-eval", !csp.include?("unsafe-eval"))
check.("CSP frame-ancestors", csp.match?(/frame-ancestors '(none|self)'/), csp[/frame-ancestors [^;]*/].inspect)
check.("CSP base-uri", csp.include?("base-uri"), csp[/base-uri [^;]*/].inspect)
check.("CSP form-action", csp.include?("form-action"), csp[/form-action [^;]*/].inspect)
check.("Permissions-Policy", h["permissions-policy"].to_s.include?("camera=()"), h["permissions-policy"].inspect)
check.("X-Frame-Options", %w[DENY SAMEORIGIN].include?(h["x-frame-options"]), h["x-frame-options"].inspect)
check.("X-Content-Type-Options", h["x-content-type-options"] == "nosniff", h["x-content-type-options"].inspect)
check.("Referrer-Policy", h["referrer-policy"].to_s.start_with?("strict-origin"), h["referrer-policy"].inspect)
cookie = h["set-cookie"].to_s
check.("Session cookie flags", %w[secure httponly samesite].all? { |f| cookie.downcase.include?(f) })
check.("No X-Powered-By", h["x-powered-by"].nil?, h["x-powered-by"].inspect)
check.("No version in Server header", !h["server"].to_s.match?(/\d+\.\d+/), h["server"].inspect)
check.("Auth page not cached", h["cache-control"].to_s.match?(/no-store|private/), h["cache-control"].inspect)

# ---------------------------------------------------------------- transport
section.("Transport / TLS")
plain = Net::HTTP.get_response(URI("http://#{host}/"))
check.("HTTP -> HTTPS redirect", plain.is_a?(Net::HTTPRedirection) && plain["location"].to_s.start_with?("https://"), plain.code)
tls_accepts = lambda do |version|
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.min_version = ctx.max_version = version
  sock = TCPSocket.new(host, 443)
  ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
  ssl.hostname = host
  ssl.connect
  true
rescue OpenSSL::SSL::SSLError, SystemCallError, IOError
  false
ensure
  ssl&.close rescue nil
  sock&.close rescue nil
end
check.("TLS 1.0 refused", !tls_accepts.(OpenSSL::SSL::TLS1_VERSION))
check.("TLS 1.1 refused", !tls_accepts.(OpenSSL::SSL::TLS1_1_VERSION))
check.("TLS 1.2 accepted", tls_accepts.(OpenSSL::SSL::TLS1_2_VERSION))
cert = http.peer_cert
days = ((cert.not_after - Time.now) / 86_400).floor
check.("Certificate valid > 14 days", days > 14, "#{days} days left")
check.("Certificate covers host", OpenSSL::SSL.verify_certificate_identity(cert, host), cert.subject.to_s)

# ---------------------------------------------------------------- exposure
section.("Nothing sensitive is served")
%w[/.git/HEAD /.git/config /.env /.env.production /config/database.yml /config/master.key /config/credentials.yml.enc
   /log/production.log /storage/ /tmp/ /db/schema.rb /Gemfile.lock /.DS_Store /backup/ /rails/info/routes
   /rails/info/properties /rails/mailers /letter_opener /sidekiq /jobs /phpinfo.php /wp-login.php
   /server-status /.well-known/../config/master.key].each do |path|
  r = request.(:get, path)
  leaked = r.code == "200" && !r.body.to_s.match?(/<html|<!DOCTYPE/i)
  leaked ||= r.code == "200" && r.body.to_s.match?(/ref: refs|BEGIN|secret_key_base|adapter:|Routes|DATABASE_URL/i)
  check.("#{path} not served", !leaked, r.code)
end

# ---------------------------------------------------------------- auth gates
section.("App pages require sign-in")
%w[/dashboard /deliveries /compliance /audit_logs /audit_logs.csv /team /billing /webhooks /alerts /vehicles/new
   /batches/new /batches/1/custody_logs /batches/1/compliance_reports /batches/1/chain-of-custody.pdf /gps
   /ops /ops/outreach /users/edit /two_factor_setup /two_factor_backup_codes].each do |path|
  r = request.(:get, path, "Accept" => "text/html")
  check.("#{path} -> sign in", redirects_to_login.(r) || r.code == "401", r.code)
end
r = request.(:get, "/api/v1/vehicles", "Accept" => "application/json")
check.("/api/v1/vehicles -> 401", r.code == "401", r.code)
r = request.(:post, "/api/v1/gps", { "Content-Type" => "application/json" }, '{"imei":"860000000000001","lat":33.4,"lng":-112}')
check.("GPS ingest without token -> 401", %w[401 403].include?(r.code), r.code)
r = request.(:post, "/stripe/webhooks", { "Content-Type" => "application/json" }, '{"type":"customer.subscription.deleted"}')
check.("Stripe webhook unsigned -> 400", r.code == "400", r.code)
r = request.(:post, "/request-a-call", { "Content-Type" => "application/x-www-form-urlencoded" },
             "call_request[name]=CSRF+probe&call_request[email]=probe%40example.com&call_request[topic]=general")
check.("Form POST without CSRF token -> 422", r.code == "422", r.code)

# ---------------------------------------------------------------- tokens
section.("Bogus tokens get a plain 404, never an error page")
{ "/dscsa-assessment/not-a-real-token" => "404", "/dscsa-assessment/not-a-real-token/report.pdf" => "404",
  "/invitations/not-a-real-token" => "404", "/verify/not-a-real-token" => "404" }.each do |path, want|
  r = request.(:get, path)
  check.("#{path.sub(/not-a-real-token/, '…')}", r.code == want && !r.body.to_s.match?(/backtrace|ActiveRecord|NoMethodError/), r.code)
end
r = request.(:get, "/unsubscribe?token=tampered--abc")
check.("Tampered unsubscribe token", r.code.start_with?("2", "3", "4") && r.code != "500", r.code)

# ---------------------------------------------------------------- errors
section.("Error handling")
r = request.(:get, "/definitely-not-a-page-#{rand(10_000)}")
check.("Unknown path -> 404", r.code == "404", r.code)
check.("404 leaks no stack/version", !r.body.to_s.match?(/backtrace|Rails\.root|ActionController::|Ruby \d|Puma \d/), "")
r = request.(:get, "/batches/1%27%20OR%201=1/custody_logs", "Accept" => "text/html")
check.("SQLi-shaped id handled", r.code != "500", r.code)
r = request.(:trace, "/")
check.("TRACE not echoed", !(r.code == "200" && r.body.to_s.include?("TRACE")), r.code)

# ---------------------------------------------------------------- injection
section.("Header / redirect injection")
r = request.(:get, "/dashboard", "X-Forwarded-Host" => "evil.example", "Accept" => "text/html")
check.("X-Forwarded-Host ignored", !r["location"].to_s.include?("evil.example"), r["location"].to_s)
r = request.(:get, "/users/sign_in?redirect_to=https://evil.example&return_to=https://evil.example")
check.("No open redirect on sign-in", !r["location"].to_s.include?("evil.example"), r.code)
r = request.(:get, "/request-a-call?topic=%3Cscript%3Ealert(1)%3C/script%3E")
check.("Reflected XSS escaped", !r.body.to_s.include?("<script>alert(1)</script>"), r.code)
r = request.(:get, "/", "Origin" => "https://evil.example")
acao = r["access-control-allow-origin"].to_s
check.("No CORS for foreign origin", !(acao == "*" || acao.include?("evil.example")), acao.inspect)

# ---------------------------------------------------------------- pages
section.("Public page hygiene")
home = request.(:get, "/").body.to_s
check.("No http:// scripts or styles", !home.match?(/<(script|link)[^>]+(src|href)="http:\/\//i))
external = home.scan(/<script[^>]+src="(https?:\/\/[^"]+)"/i).flatten.reject { |u| u.include?(host) }
warn_check.("External scripts", external.empty?, external.join(", ").then { |s| s.empty? ? "none" : s })
r = request.(:get, "/.well-known/security.txt")
warn_check.("security.txt published", r.code == "200", r.code)

# ---------------------------------------------------------------- email DNS
section.("Email authentication (DNS)")
dns = Resolv::DNS.new
txt = ->(name) { dns.getresources(name, Resolv::DNS::Resource::IN::TXT).map { |t| t.strings.join } rescue [] }
spf = txt.(host).find { |t| t.start_with?("v=spf1") }
warn_check.("SPF record", !spf.nil?, spf.to_s[0, 80])
warn_check.("SPF not +all", !spf.to_s.include?("+all"), "")
dmarc = txt.("_dmarc.#{host}").find { |t| t.start_with?("v=DMARC1") }
warn_check.("DMARC record", !dmarc.nil?, dmarc.to_s[0, 80])
warn_check.("DMARC policy enforces", dmarc.to_s.match?(/p=(quarantine|reject)/), dmarc.to_s[/p=\w+/].to_s)
cname = dns.getresources("pm-bounces.#{host}", Resolv::DNS::Resource::IN::CNAME).first
warn_check.("Postmark Return-Path CNAME", !cname.nil?, cname&.name.to_s)
if (selector = ENV["DKIM_SELECTOR"])
  key = txt.("#{selector}._domainkey.#{host}").find { |t| t.include?("p=") }
  warn_check.("DKIM #{selector}", !key.nil?, key.to_s[0, 40])
else
  puts "INFO  DKIM                               selector is per-account: DKIM_SELECTOR=<from Postmark> ruby test_infosec.rb"
end

http.finish
puts "\n#{failures.zero? ? 'All checks passed' : "#{failures} check(s) FAILED"}#{warnings.positive? ? " (#{warnings} warning#{'s' unless warnings == 1})" : ''}."
exit(failures.zero? ? 0 : 1)
