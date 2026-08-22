class ShipmentsController < ApplicationController
  def index
    render plain: "Shipments OK", layout: false
  end
end
