class LandingController < ApplicationController
  def index
    @vehicles_count = 47
    render layout: false  # NO application.html.erb (no blue bar!)
  end
end
