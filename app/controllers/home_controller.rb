class HomeController < ApplicationController
  def index
    render 'home/index', layout: false  # ← DISABLES DOUBLE NAVBAR
  end
end
