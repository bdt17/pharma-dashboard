class GpsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def update
    render plain: "GPS OK", status: 200, layout: false
  end
end
