class DashboardController < ApplicationController
  def index
    render plain: <<~HTML, layout: false
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
      <style>
        :root{--primary-blue:#0984C0;--lighter-blue:#60BDD1;--silver-sand:#C0BEC6;}
        body{background:#000;color:#fff;font-family:'Courier',monospace;padding:40px 16px;display:flex;justify-content:center;align-items:flex-start;}
        .dashboard{max-width:1100px;width:100%;}
        .logo{font-size:2.5rem;font-weight:700;color:var(--primary-blue);letter-spacing:.08em;text-shadow:0 2px 8px rgba(9,132,192,.5);}
        .subtitle{font-size:1.1rem;color:var(--silver-sand);margin-top:8px;}
        .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;margin-top:32px;}
        .card{background:rgba(255,255,255,.1);border:1px solid var(--primary-blue);border-radius:8px;padding:20px;color:#fff;}
        .card-main{font-size:2.2rem;font-weight:700;color:var(--primary-blue);}
        .card-title{font-size:.95rem;text-transform:uppercase;color:var(--silver-sand);margin-bottom:8px;}
        .badge{margin-top:28px;padding:14px 18px;border:2px solid var(--primary-blue);background:rgba(9,132,192,.2);font-size:.95rem;}
        a{color:var(--lighter-blue);font-weight:600;text-decoration:none;}
      </style>
    HTML
  end
end
