class HomeController < ApplicationController
  def index
  end
  def vehicles
    render 'index'  # Reuse dashboard view for now
  end
  def gps
    render 'index'
  end
end
