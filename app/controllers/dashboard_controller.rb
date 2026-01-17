class DashboardController < ApplicationController
  def index
    render plain: <<~HTML
      <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 800px; margin: 0 auto; padding: 2rem;">
        <h1 style="color: #0984C0; font-size: 3rem; font-weight: 900; text-align: center; margin-bottom: 1rem;">
          🩺 Pharma Transport Dashboard
        </h1>
        <p style="text-align: center; font-size: 1.2rem; color: #565759; margin-bottom: 3rem;">
          Phase 14 LIVE - GPS + AI + Marketplace
        </p>
        
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 2rem; margin-bottom: 3rem;">
          <div style="background: white; padding: 2rem; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); border: 1px solid #AAA7B0;">
            <div style="font-size: 3rem; margin-bottom: 1rem;">🚛</div>
            <h3 style="font-size: 1.1rem; color: #565759; margin-bottom: 0.5rem; font-weight: 600;">Live Vehicles</h3>
            <div style="font-size: 3rem; font-weight: 900; color: #0984C0;">24</div>
          </div>
          
          <div style="background: white; padding: 2rem; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); border: 1px solid #AAA7B0;">
            <div style="font-size: 3rem; margin-bottom: 1rem;">📦</div>
            <h3 style="font-size: 1.1rem; color: #565759; margin-bottom: 0.5rem; font-weight: 600;">Active Batches</h3>
            <div style="font-size: 3rem; font-weight: 900; color: #0984C0;">127</div>
          </div>
          
          <div style="background: white; padding: 2rem; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); border: 1px solid #AAA7B0;">
            <div style="font-size: 3rem; margin-bottom: 1rem;">🚨</div>
            <h3 style="font-size: 1.1rem; color: #565759; margin-bottom: 0.5rem; font-weight: 600;">Alerts</h3>
            <div style="font-size: 3rem; font-weight: 900; color: #0984C0;">3</div>
          </div>
          
          <div style="background: white; padding: 2rem; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); border: 1px solid #AAA7B0;">
            <div style="font-size: 3rem; margin-bottom: 1rem;">💰</div>
            <h3 style="font-size: 1.1rem; color: #565759; margin-bottom: 0.5rem; font-weight: 600;">Revenue</h3>
            <div style="font-size: 3rem; font-weight: 900; color: #0984C0;">$12K</div>
          </div>
        </div>
        
        <div style="text-align: center;">
          <a href="/vehicles" style="background: #0984C0; color: white; padding: 1rem 2rem; border-radius: 12px; font-weight: 700; font-size: 1.2rem; text-decoration: none; box-shadow: 0 8px 20px rgba(9,132,192,0.3); display: inline-block; transition: all 0.3s;">
            🚛 View All Vehicles
          </a>
        </div>
      </div>
    HTML
  end
end
