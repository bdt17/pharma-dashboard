class DashboardController < ApplicationController
  def index
    render inline: '<h1 style="color:#0984C0;font-size:3rem;text-align:center">🩺 Pharma Transport<br><span style="font-size:1.5rem;color:#565759">Phase 14 LIVE - 24 Vehicles | $12K Revenue</span></h1>'
  end
end
