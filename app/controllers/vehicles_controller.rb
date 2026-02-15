class VehiclesController < ApplicationController
  def index
    render html: '<h1>Vehicles Dashboard</h1><p>48 active trucks online</p>'
  end
end
