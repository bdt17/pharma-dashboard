class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true unless Rails.env.test?

  # Devise authentication - SKIP for public teaser pages
  before_action :authenticate_user!, unless: :public_endpoint?
  
  # Your existing public methods (stay public)
  def index
    render "dashboard/index"
  end

  def dashboard
    render "dashboard/index"
  end

  def health
    render plain: "Thomas IT Health OK", status: 200
  end

  def vehicles
    render plain: "PHX001 GPS Tracking LIVE", status: 200
  end

  def batches
    render plain: "FDA 21 CFR Part 11 READY", status: 200
  end

  def gps_update
    render json: {status: "GPS OK"}, status: 200
  end

  private

  # Skip auth for your public teaser endpoints
  def public_endpoint?
    %w[index dashboard health vehicles batches gps_update].include?(action_name)
  end
end
