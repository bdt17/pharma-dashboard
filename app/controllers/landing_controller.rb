class LandingController < ApplicationController
  def index
    @vehicles_count = 47
    render layout: false  # NO application layout!
  end
end
