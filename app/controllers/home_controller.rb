class HomeController < ApplicationController
  def index
    render html: <<-HTML.strip_heredoc.html_safe
      <!DOCTYPE html>
      <html>
      <head>
        <title>Pharma Transport Dashboard</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            background: #FFFFFF; 
            min-height: 100vh; 
            padding: 40px 20px;
          }
          .container { max-width: 1400px; margin: 0 auto; }
          .header { 
            text-align: center; 
            background: linear-gradient(135deg, #0984C0 0%, #60BDD1 100%); 
            color: #FFFFFF; 
            padding: 60px 40px; 
            border-radius: 20px; 
            margin-bottom: 60px;
            box-shadow: 0 20px 40px rgba(9,132,192,0.3);
          }
          .header h1 { 
            font-size: 64px; font-weight: 800; 
            margin-bottom: 20px; 
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
          }
          .header p { font-size: 28px; opacity: 0.95; }
          .stats { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(380px, 1fr)); 
            gap: 40px; 
            margin-bottom: 80px;
          }
          .widget { 
            background: #FFFFFF; 
            padding: 50px 40px; 
            border-radius: 20px; 
            box-shadow: 0 20px 60px rgba(0,0,0,0.1);
            border: 1px solid #C0BEC6;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
          }
          .widget:hover { 
            transform: translateY(-8px); 
            box-shadow: 0 30px 80px rgba(9,132,192,0.2);
          }
          .title { 
            font-size: 24px; 
            font-weight: 600; 
            color: #565759; 
            margin-bottom: 20px; 
            letter-spacing: 1px;
          }
          .metric { 
            font-size: 96px; 
            font-weight: 900; 
            color: #0984C0; 
            margin-bottom: 20px;
            font-family: 'SF Pro Display', -apple-system, sans-serif;
          }
          .growth .metric { color: #28a745; }
          .subtitle { 
            font-size: 20px; 
            color: #565759; 
            line-height: 1.6;
          }
          .status { 
            text-align: center; 
            color: #565759; 
            font-size: 24px; 
            padding: 40px;
            background: linear-gradient(135deg, #F8F9FA 0%, #E9ECEF 100%);
            border-radius: 20px;
            border-left: 6px solid #0984C0;
          }
          @media (max-width: 768px) {
            .header h1 { font-size: 48px; }
            .metric { font-size: 72px; }
            .stats { grid-template-columns: 1fr; gap: 30px; }
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚛 PHARMA TRANSPORT 💉📍</h1>
            <p>Phase 14 LIVE</p>
          </div>
          
          <div class="stats">
            <div class="widget">
              <div class="title">GPS Vehicles</div>
              <div class="metric">24</div>
              <div class="subtitle">GPS Tracked • Real-time</div>
            </div>
            
            <div class="widget">
              <div class="title">Batches</div>
              <div class="metric">127</div>
              <div class="subtitle">FDA Compliant • Temp Controlled</div>
            </div>
            
            <div class="widget growth">
              <div class="title">Phase 14 Growth</div>
              <div class="metric">+18%</div>
              <div class="subtitle">Month over Month</div>
            </div>
          </div>
          
          <div class="status">
            ✅ LIVE PRODUCTION • 24hr Uptime • FDA Ready<br>
            Next: GPS Map • Temp Alerts • Route Optimization
          </div>
        </div>
      </body>
      </html>
    HTML
  end
end
