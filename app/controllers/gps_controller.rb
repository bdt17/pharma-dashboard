class GpsController < ApplicationController
  skip_before_action :authenticate_user!

  def update
    render plain: "📡 GPS UPDATE RECEIVED", status: 200
  end

  def stream
    render plain: "📡 GPS STREAM LIVE", status: 200
  end
end
