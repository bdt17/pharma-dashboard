class Api::HealthController < ApplicationController
  def index
    render json: { 
      status: 'ok', 
      uptime: Rails.env.production? ? 'production' : 'development',
      timestamp: Time.current.iso8601,
      version: Rails.version 
    }
  end
end
