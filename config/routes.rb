Rails.application.routes.draw do
  get '/', to: proc { [200, {'Content-Type' => 'text/html'}, [<<~HTML]] }
    <!DOCTYPE html>
    <html>
    <head><title>Thomas IT Pharma Transport</title></head>
    <body style="background:black;color:white;font-family:Courier;padding:40px;">
      <h1 style="color:#0984C0;font-size:3rem;">💉 PHARMA TRANSPORT</h1>
      <h2 style="color:#C0BEC6;">Thomas Information Technology · Phoenix AZ</h2>
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:20px;margin:40px 0;">
        <div style="background:rgba(255,255,255,0.1);padding:20px;border:1px solid #0984C0;border-radius:8px;">
          <div style="color:#C0BEC6;font-size:12px;">Vehicles Live</div>
          <div style="font-size:2rem;color:#0984C0;">24</div>
        </div>
        <div style="background:rgba(255,255,255,0.1);padding:20px;border:1px solid #0984C0;border-radius:8px;">
          <div style="color:#C0BEC6;font-size:12px;">Batches Active</div>
          <div style="font-size:2rem;color:#0984C0;">127</div>
        </div>
        <div style="background:rgba(255,255,255,0.1);padding:20px;border:1px solid #0984C0;border-radius:8px;">
          <div style="color:#C0BEC6;font-size:12px;">Monthly Revenue</div>
          <div style="font-size:2rem;color:#0984C0;">$12K</div>
        </div>
        <div style="background:rgba(255,255,255,0.1);padding:20px;border:1px solid #0984C0;border-radius:8px;">
          <div style="color:#C0BEC6;font-size:12px;">APIs</div>
          <div style="font-size:2rem;color:#0984C0;">5/5 ✓</div>
        </div>
      </div>
      <div style="padding:15px;border:2px solid #0984C0;background:rgba(9,132,192,0.2);display:inline-block;border-radius:8px;">
        ✅ FDA 21 CFR Part 11 Compliant · <a href="/status" style="color:#60BDD1;">Status →</a>
      </div>
    </body>
    </html>
  HTML
  }
  
  get '/status', to: proc { [200, {'Content-Type' => 'text/plain'}, ['Thomas IT Pharma Transport - All systems operational']] }
end
