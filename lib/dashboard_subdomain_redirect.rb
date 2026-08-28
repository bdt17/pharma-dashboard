# `dashboard.<domain>` is a Render custom domain that only exists as a
# memorable shortcut -- it is not the app's canonical host. Every request on
# it gets a 301 to the canonical host (APP_HOST): the bare host lands on
# /dashboard (which then gates on sign-in via authenticate_user!), any deeper
# path keeps its path and query string. Staying on one host means one session
# cookie rather than a separate login per subdomain.
#
# This is middleware rather than a route because the only clean way to express
# "every method, every path, this host" in the routes file is a catch-all with
# an explicit `via: :head`, and that shadows the implicit HEAD handling Rails
# adds to `root` -- which broke `HEAD /` (Render's health check) for all hosts.
class DashboardSubdomainRedirect
  def initialize(app)
    @app = app
  end

  def call(env)
    host = env["HTTP_HOST"].to_s.split(":").first.to_s.downcase
    return @app.call(env) unless host.start_with?("dashboard.")

    request = Rack::Request.new(env)
    path = request.path == "/" ? "/dashboard" : request.path
    query = request.query_string.empty? ? "" : "?#{request.query_string}"
    location = "https://#{canonical_host}#{path}#{query}"

    [ 301, { "Location" => location, "Content-Type" => "text/plain", "Cache-Control" => "no-store" },
      [ "Moved permanently to #{location}\n" ] ]
  end

  private

  def canonical_host
    ENV.fetch("APP_HOST", "pharmatransport.org")
  end
end
