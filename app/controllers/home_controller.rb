class HomeController < ApplicationController
  def index
    render plain: "Pharma Transport Dashboard v9.2 - LIVE", status: 200
  end
end
