class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update
    # Simple response - no DB needed yet
    head :ok
  end

  def stream
    render json: { status: 'live', vehicle: 1 }
  end
end
