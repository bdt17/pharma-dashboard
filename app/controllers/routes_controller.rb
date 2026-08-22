class RoutesController < ApplicationController
  def index
    render plain: "Routes OK", layout: false
  end
end
