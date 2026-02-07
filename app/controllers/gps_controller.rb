class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def update
    head :no_content
  end

  def stream
    render plain: "GPS LIVE"
  end
end
