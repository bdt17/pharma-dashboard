class GpsController < ApplicationController
  def update
    render plain: "GPS OK", status: :ok
  end

  def stream
    render plain: "GPS stream OK", status: :ok
  end
end
