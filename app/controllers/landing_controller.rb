class LandingController < ApplicationController
  def index
    render plain: File.read(Rails.root.join('public', 'landing.html')), 
           layout: false, 
           content_type: 'text/html'
  end
end
