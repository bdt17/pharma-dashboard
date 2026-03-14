require 'rack'

class PharmaTransportApp
  def self.call(env)
    path = env["PATH_INFO"]
    
    case path
    when "/favicon.ico"
      [204, {}, []]
    when "/"
      [200, {"Content-Type" => "text/html"}, [thomas_it_landing_html]]
    when "/login", "/users/sign_in", "/users/sign_up"
      [200, {"Content-Type" => "text/html"}, [thomas_it_login_html]]
    when "/dashboard", "/enterprise/dashboard"
      [200, {"Content-Type" => "text/html"}, [thomas_it_dashboard_html]]
    when "/gps", "/api/vehicles"
      [200, {"Content-Type" => "application/json"}, [vehicles_json]]
    when %r{/batches/(\d+)/chain-of-custody\.pdf$}
      batch_id = $1
      [200, {"Content-Type" => "application/pdf", "Content-Disposition" => "attachment; filename=CoC-#{batch_id}.pdf"}, [coc_pdf(batch_id)]]
    when "/health", "/batches", "/billing", "/subscribe", "/landing", "/signup", "/vehicles"
      [200, {"Content-Type" => "text/html"}, [thomas_it_page(path)]]
    when "/auth/enterprise"
      [302, {"Location" => "/dashboard"}, []]
    else
      [404, {"Content-Type" => "application/json"}, [{"error": "Not Found"}.to_json]]
    end
  end

  # [ALL PHASE 10 METHODS HERE - landing_html, login_html, dashboard_html, etc - copy from working backup]
  def self.thomas_it_landing_html
    # ... [paste your working landing page HTML from before Phase 11]
  end

  # ... [all other methods unchanged]

end

run PharmaTransportApp
