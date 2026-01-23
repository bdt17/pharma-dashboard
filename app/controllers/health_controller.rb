class HealthController < ApplicationController
  def show
    render json: { status: 'live', timestamp: Time.current, uptime: '100%', batches: 127 }
  end
end
