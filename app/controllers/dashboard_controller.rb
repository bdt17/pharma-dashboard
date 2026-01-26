class DashboardController < ApplicationController
  def index
    render html: <<~HTML.html_safe, layout: false
      <div class="dashboard">
        <h1 class="logo">💉 PHARMA TRANSPORT</h1>
        <h2 class="subtitle">Thomas Information Technology · Phoenix AZ</h2>
        <div class="grid">
          <div class="card"><div class="card-title">Vehicles Live</div><div class="card-main">24</div></div>
          <div class="card"><div class="card-title">Batches Active</div><div class="card-main">127</div></div>
          <div class="card"><div class="card-title">Monthly Revenue</div><div class="card-main">$12K</div></div>
          <div class="card"><div class="card-title">APIs</div><div class="card-main">5/5 ✓</div></div>
        </div>
        <div class="badge">✅ FDA 21 CFR Part 11 Compliant · <a href="/reports/chain-of-custody/B001">B001 →</a></div>
      </div>
      <style>#{INLINE_CSS_HERE}</style>
    HTML
  end
end
