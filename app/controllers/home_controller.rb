# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    render html: '<h1>Pharma Transport Dashboard</h1><p>$500K ARR Ready</p>'.html_safe
  end
end
