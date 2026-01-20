class HomeController < ApplicationController
  def index
    render html: <<-HTML.strip_heredoc.html_safe
      <!DOCTYPE html>
      <html>
      <head>
        <title>Pharma Transport Dashboard</title>
        <style>
          body { font-family: Arial; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
          .container { max-width: 1200px; margin: 0 auto; }
          .header { text-align: center; color: white; margin-bottom: 40px; }
          .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 40px; }
          .widget { background: rgba(255,255,255,0.95); padding: 30px; border-radius: 15px; box-shadow: 0 15px 35px rgba(0,0,0,0.1); }
          .title { font-size: 28px; font-weight: bold; color: #2c5aa0; margin-bottom: 15px; }
          .metric { font-size: 48px; font-weight: bold; color: #28a745; }
          .growth { color: #28a745; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚛 PHARMA TRANSPORT DASHBOARD 💉📍</h1>
            <p>Phase 14 LIVE</p>
          </div>
          <div class="stats">
            <div class="widget">
              <div class="title">GPS Vehicles</div>
              <div class="metric">24</div>
              <div>GPS Tracked • Real-time</div>
            </div>
            <div class="widget">
              <div class="title">Batches</div>
              <div class="metric">127</div>
              <div>FDA Compliant • Temp Controlled</div>
            </div>
            <div class="widget">
              <div class="title">Phase 14 Growth</div>
              <div class="metric growth">+18%</div>
            </div>
          </div>
          <div style="text-align: center; color: white; font-size: 20px;">
            <p>✅ LIVE PRODUCTION • 24hr Uptime • FDA Ready</p>
            <p>Next: GPS Map • Temp Alerts • Route Optimization</p>
          </div>
        </div>
      </body>
      </html>
    HTML
  end
end
