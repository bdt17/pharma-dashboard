class HealthController < ApplicationController
  def index
    render json: { status: 'ok', rails: '8.1', solid: 'cache/queue/cable', timestamp: Time.now.utc }
  end
end
