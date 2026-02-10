class DashboardController < ApplicationController
  def index
    render layout: 'application' # FORCE LAYOUT!
  end

  def vehicles
    render layout: 'application'
  end

  # Add this to ALL your controllers the same way
  def billing
    render layout: 'application'
  end

  def batches
    render layout: 'application'
  end

  def safe
    render layout: 'application'
  end
end
