class RoutesController < ApplicationController
  def index
    render plain: "Active Routes: Phoenix → Tucson", status: :ok
  end
end
