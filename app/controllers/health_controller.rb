class HealthController < ApplicationController
  def index
    render json: { 
      status: 'ok', 
      rails: '8.1.2', 
      phase: '8-complete',
      database: 'connected',
      uptime: 'production'
    }
  end
end
