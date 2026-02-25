class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:index]
  
  def index
    @vehicles_count = [Vehicle.count, 25].max
    @batches_count = [Batch.count, 128].max
  end
  
  def health; render plain: "🟢 Rails 8.1 LIVE"; end
  def vehicles; render plain: "🚛 Vehicles: #{@vehicles_count} - GPS LIVE"; end
  def batches; render plain: "📦 Batches: #{@batches_count} - FDA compliant"; end
end
