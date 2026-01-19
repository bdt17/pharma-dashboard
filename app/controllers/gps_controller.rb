class GpsController < ApplicationController
  layout false
  
  def dashboard
    @vehicles = [
      OpenStruct.new(identifier: 'PT-001', lat: 33.4484, lng: -112.0740, status: 'Active'),
      OpenStruct.new(identifier: 'PT-002', lat: 33.4621, lng: -112.0668, status: 'En Route'),
      OpenStruct.new(identifier: 'PT-003', lat: 33.4372, lng: -112.0824, status: 'Idle')
    ]
    render layout: false
  end
end
