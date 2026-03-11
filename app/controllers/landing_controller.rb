class LandingController < ApplicationController
  def index
    @vehicles_count = 47
    render layout: 'landing', formats: [:html]  # Force landing layout only
  end
end
