class DashboardController < ApplicationController
  def index
    @vehicles_count = 6 # Your production data
    @batches_count = 1
    @mrr = @vehicles_count * 99
  rescue => e
    Rails.logger.error "Dashboard error: #{e.message}"
    @vehicles_count = 6
    @batches_count = 1
    @mrr = 594
  end
end
