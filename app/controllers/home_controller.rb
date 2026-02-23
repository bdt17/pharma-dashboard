# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    # Removed render - uses view + layout
  end
end

  def index
    render plain: 'Pharma Transport Dashboard v9.2', status: 200
  end

def index; render plain: 'Pharma Transport Dashboard v9.2'; end
