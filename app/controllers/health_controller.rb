class HealthController < ApplicationController
  def index
    render json: { status: 'ok', version: 'v8.7', timestamp: Time.now }, status: :ok
  end
end
