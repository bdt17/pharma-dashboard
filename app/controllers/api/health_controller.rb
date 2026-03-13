class Api::HealthController < ApplicationController
  def index
    render json: { status: "OK", timestamp: Time.current }
  end
end
