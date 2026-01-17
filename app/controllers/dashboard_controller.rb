class DashboardController < ApplicationController
  def index
    @vehicles = 24
    @batches = 127
    @alerts = 3
    render file: Rails.root.join('public', 'dashboard.html') if File.exist?(Rails.root.join('public', 'dashboard.html'))
  end

  def pfizer
    render :index
  end
end
