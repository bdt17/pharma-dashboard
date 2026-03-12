class HomeController < ApplicationController
  def index
    # Render home/index.html.erb with NO layout (single navbar, no double header)
    render "home/index", layout: false
  end
end
