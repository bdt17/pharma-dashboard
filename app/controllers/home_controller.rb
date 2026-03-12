class HomeController < ApplicationController
  rescue_from StandardError do |e|
    head :ok
  end
  
  def index
    head :ok
  end
end
