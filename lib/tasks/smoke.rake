require "net/http"

namespace :smoke do
  # Public-surface smoke test against a running deployment. Not a unit test
  # -- it makes real HTTP requests, so it lives here rather than in test/.
  #
  #   bin/rails smoke:check                         # -> https://pharmatransport.org
  #   SMOKE_HOST=https://staging.example.com bin/rails smoke:check
  #   bin/rails "smoke:check[http://localhost:3000]"
  #
  # Exits non-zero on the first failure so CI / a cron can gate on it.
  CHECKS = [
    { method: :get,  path: "/",                  status: 200, includes: "Pharma Transport" },
    { method: :get,  path: "/health",            status: 200, includes: "ok" },
    { method: :get,  path: "/pricing",           status: 200, includes: [ "Starter", "Pro", "Compliance" ] },
    { method: :get,  path: "/security",          status: 200, includes: "survive an audit" },
    { method: :get,  path: "/compliance-officer", status: 200, includes: "Fractional Compliance Officer" },
    { method: :get,  path: "/dscsa-assessment",  status: 200, includes: "readiness" },
    { method: :get,  path: "/request-a-call",    status: 200, includes: "call" },
    { method: :get,  path: "/terms",             status: 200, includes: "Terms of Service" },
    # Auth-gated surfaces should redirect, not error or 200.
    { method: :get,  path: "/dashboard",         status: 302 },
    { method: :get,  path: "/billing",           status: 302 },
    { method: :get,  path: "/ops",               status: [ 302, 404 ] },
    # The Stripe webhook must reject an unsigned POST (400), not 404 or 500.
    { method: :post, path: "/stripe/webhooks",   status: 400 }
  ].freeze

  # No :environment dependency on purpose -- this is pure Net::HTTP, so it
  # runs without booting Rails or a database.
  task :check, [ :host ] do |_task, args|
    base = (args[:host] || ENV["SMOKE_HOST"] || "https://pharmatransport.org").chomp("/")
    uri  = URI.parse(base)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 15

    failures = []
    puts "Smoke check: #{base}"

    CHECKS.each do |check|
      label = "#{check[:method].to_s.upcase} #{check[:path]}"
      begin
        request = (check[:method] == :post ? Net::HTTP::Post : Net::HTTP::Get).new(check[:path])
        request.body = "{}" if check[:method] == :post
        request["Content-Type"] = "application/json" if check[:method] == :post
        response = http.request(request)

        problems = []
        expected = Array(check[:status])
        problems << "status #{response.code} (want #{expected.join('/')})" unless expected.map(&:to_s).include?(response.code)
        body = response.body.to_s.dup.force_encoding("UTF-8")
        Array(check[:includes]).each do |needle|
          problems << "missing #{needle.inspect}" unless body.include?(needle)
        end

        if problems.empty?
          puts "  ok    #{label}"
        else
          puts "  FAIL  #{label} -- #{problems.join('; ')}"
          failures << label
        end
      rescue StandardError => e
        puts "  ERROR #{label} -- #{e.class}: #{e.message}"
        failures << label
      end
    end

    if failures.any?
      abort "\n#{failures.size} smoke check(s) failed: #{failures.join(', ')}"
    else
      puts "\nAll #{CHECKS.size} checks passed."
    end
  end
end
