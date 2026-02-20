class GpsController < ApplicationController
  skip_before_action :authenticate_user!

  def update
    Rails.logger.info "GPS Update: #{params.inspect}"
    head :ok
  end

  def stream
    render plain: "ActionCable GPS stream ready"
  end
end
