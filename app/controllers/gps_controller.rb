class GpsController < ApplicationController
  skip_before_action :authenticate_user!

  def update
    head :ok
  end

  def stream
    render plain: "GPS ready", status: :ok
  end
end
