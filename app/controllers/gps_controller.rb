class GpsController < ApplicationController
  def index
    render plain: 'Gps OK', layout: false
  end
end
