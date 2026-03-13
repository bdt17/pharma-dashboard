class ShipmentsController < ApplicationController
  def index
    render plain: "Shipments Dashboard - All Active", status: :ok
  end
end
