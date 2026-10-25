class Api::HealthController < ApplicationController
  skip_before_action :enforce_two_factor
  def index
    render json: { status: "OK", timestamp: Time.current }
  end
end
