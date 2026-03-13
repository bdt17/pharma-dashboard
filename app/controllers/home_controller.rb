class HomeController < ApplicationController
  def index
    render html: '<h1 style="color: #1e40af; text-align: center;">🩺 PHARMA TRANSPORT ENTERPRISE DASHBOARD</h1><div style="text-align: center; font-size: 1.2rem; color: #047857;">Phase 10 SaaS • FDA 21 CFR Part 11 Compliant • Multi-Tenant Ready</div>', layout: 'application'
  end

  def vehicles
    render html: '<h1 style="color: #1e40af;">🚛 VEHICLE FLEET</h1><p>GPS Tracking • Cold Chain Monitoring • Real-time Location</p>', layout: 'application'
  end

  def gps
    render html: '<h1 style="color: #1e40af;">🛰️ GPS TRACKING</h1><p>GV55 IoT Devices • Temperature Alerts • Route Optimization</p>', layout: 'application'
  end
end
