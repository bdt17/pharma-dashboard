class TrucksController < ApplicationController
  def index
    render plain: "Trucks OK", layout: false
  end
end
